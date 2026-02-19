import wat, { 
    i32, f32, i64, f64, v128, 
    extern, externref, funcref, shared,
    func, start, type, param, result,
    local, global,
    ref, data, elem, drop,
    table, memory, 
    call, call_indirect, select,
    loop, br, br_if, nop, unreachable
} from "./WatProxy.mjs"

import opdlog from "./chain_opdlog.mjs";

let tbl_ext = [], tbl_fun = [];

export class ChainQueue extends Array {
    add () { return this.push(...arguments), this; }
    get buffer () { return Buffer.concat(this.map(o => o.buffer)) }
}

export class ChainOperation {

    static COUNT_OP_HEADERS = 0;
    static BYTES_PER_HEADER = Uint32Array.BYTES_PER_ELEMENT;
    static ELEMENT_FUNCREFS = new Array(null);

    static HEADERS = {
        BYTES_PER_OPERATION : this.headerCount++,
        CALL_INDIRECT_INDEX : this.headerCount++,
    };
    static get OFFSET () {
        return Object.fromEntries(
            Object.keys(this.HEADERS).map(key => [
                key, this.offsetAt(this.HEADERS[key])
            ])
        );
    }

    static get BYTES_PER_OPERATION () { return this.offsetAt(this.headerCount); }
    static get CALL_INDIRECT_INDEX () { return this.ELEMENT_FUNCREFS.indexOf(this.$name) };
    static get CALL_INDIRECT_$NAME () { return this.ELEMENT_FUNCREFS.at(this.CALL_INDIRECT_INDEX) };

    get BYTES_PER_OPERATION () { return this.constructor.BYTES_PER_OPERATION; }
    get CALL_INDIRECT_INDEX () { return this.constructor.CALL_INDIRECT_INDEX; }
    get CALL_INDIRECT_$NAME () { return this.constructor.CALL_INDIRECT_$NAME; }

    get BYTES_PER_HEADER    () { return this.constructor.BYTES_PER_HEADER; }
    get COUNT_OP_HEADERS    () { return this.constructor.COUNT_OP_HEADERS; }
    
    get HEADERS () { return this.constructor.HEADERS; }

    static get headerCount () { return this.COUNT_OP_HEADERS; }
    static set headerCount (v) { this.COUNT_OP_HEADERS = v; }
    static offsetAt (index) { 
        if (typeof index !== "number" || index < 0) {
            throw {
                error: `Offset request from unknown index!`,
                arguments: arguments,
                constructor: this.name
            }
        }
        return index * this.BYTES_PER_HEADER 
    }

    static registerHeaders ($name, headers) { 
        this.ELEMENT_FUNCREFS.push($name);
        this.$name = $name;

        const proto = Reflect.getPrototypeOf(this);
        const pheaders = structuredClone(proto.HEADERS); 

        return Object.assign(pheaders, headers);
    }

    offsetAt (index) { return this.constructor.offsetAt(index) }

    setHeader (index, value = 0) { this.buffer.writeUint32LE(value, this.offsetAt(index)); }
    getHeader (index) { return this.buffer.readUint32LE(this.offsetAt(index));}

    static getHeader (index) { return Reflect.get(this, Object.keys(this.HEADERS).at(index)) }
    static setHeader (index, value) { Reflect.set(this, Object.keys(this.HEADERS).at(index), value) }

    get buffer () { 
        return Object.defineProperty(this, "buffer", {
            value: Buffer.alloc(this.BYTES_PER_OPERATION),
            configurable: true, writable: true 
        }).buffer; 
    }

    static from ( ...args ) {
        const op = new this();
        
        let header_i = this.COUNT_OP_HEADERS;
        let argval_i = args.length;

        const reqlen = header_i - this.__proto__.COUNT_OP_HEADERS;

        if (args.length < reqlen) {
            throw {
                error: `At least ${reqlen} parameters required to create a new operation!`,
                arguments,
                constructor: this.name
            };
        }

        while (argval_i > 0) { 
            op.setHeader(--header_i, args[--argval_i]);
        }

        while (header_i-- > 0) {
            op.setHeader(header_i, this.getHeader(header_i));
        }

        return op;
    }

    get result () { return this.getHeader(this.RESULT_HEADER_INDEX ?? -1) }

    get dump () { opdlog(this) }
}

export class GrowTableChainOperation extends ChainOperation {
    static HEADERS = this.registerHeaders( "$grow_table", {
        PARAM0_EXTERN_GROW_LENGTH : this.headerCount++,
        RESULT_FIRST_EXTERN_INDEX : this.headerCount++,
    });

    static RESULT_HEADER_INDEX = this.HEADERS.RESULT_FIRST_EXTERN_INDEX;
    static get PARAM0_EXTERN_GROW_LENGTH () { return 1; }

    set grow_count ( value ) { this.setHeader(this.HEADERS.PARAM0_EXTERN_GROW_LENGTH, value); }
    get grow_count () { return this.getHeader(this.HEADERS.PARAM0_EXTERN_GROW_LENGTH); }

    set first_index ( value ) { this.setHeader(this.HEADERS.RESULT_FIRST_EXTERN_INDEX, value); }
    get first_index () { return this.getHeader(this.HEADERS.RESULT_FIRST_EXTERN_INDEX); }
}

export class CopyMemoryChainOperation extends ChainOperation {
    static HEADERS = this.registerHeaders( "$copy_memii", {
        PARAM0_DST_WRITER_OFFSET : this.headerCount++,
        PARAM1_SRC_READER_OFFSET : this.headerCount++,
        PARAM2_LEN_MEMCPY_LENGTH : this.headerCount++,
    });

    static get PARAM0_DST_WRITER_OFFSET () { throw "Copy operation trying to write heap begin!"; }

    set dst_writer_offset   ( value ) { this.setHeader(this.HEADERS.PARAM0_DST_WRITER_OFFSET, value); }
    get dst_writer_offset   () { return this.getHeader(this.HEADERS.PARAM0_DST_WRITER_OFFSET); }

    set src_reader_offset   ( value ) { this.setHeader(this.HEADERS.PARAM2_SRC_READER_OFFSET, value); }
    get src_reader_offset   () { return this.getHeader(this.HEADERS.PARAM2_SRC_READER_OFFSET); }

    set len_memcpy_length   ( value ) { this.setHeader(this.HEADERS.PARAM2_LEN_MEMCPY_LENGTH, value); }
    get len_memcpy_length   () { return this.getHeader(this.HEADERS.PARAM2_LEN_MEMCPY_LENGTH); }
}

export class NewArrayChainOperation extends ChainOperation {

    static HEADERS = this.registerHeaders( "$wasm_array", {
        RESULT_GROW_EXTERN_TABLE_INDEX : this.headerCount++,
    });

    static RESULT_HEADER_INDEX = this.HEADERS.RESULT_GROW_EXTERN_TABLE_INDEX;

    set grow_ext_idx ( value ) { this.setHeader(this.HEADERS.RESULT_GROW_EXTERN_TABLE_INDEX, value); }
    get grow_ext_idx () { return this.getHeader(this.HEADERS.RESULT_GROW_EXTERN_TABLE_INDEX); }
}

export class ApplyChainOperation extends ChainOperation {

    static HEADERS = this.registerHeaders( "$wasm_apply", {
        PARAM0_FUNC_EXTERN_TABLE_INDEX : this.headerCount++,
        PARAM1_THIS_EXTERN_TABLE_INDEX : this.headerCount++,
        PARAM2_ARGV_EXTERN_TABLE_INDEX : this.headerCount++,
        RESULT_GROW_EXTERN_TABLE_INDEX : this.headerCount++,
    });

    static RESULT_HEADER_INDEX = this.HEADERS.RESULT_GROW_EXTERN_TABLE_INDEX;

    set grow_ext_idx ( value ) { this.setHeader(this.HEADERS.RESULT_GROW_EXTERN_TABLE_INDEX, value); }
    set func_ext_idx ( value ) { this.setHeader(this.HEADERS.PARAM0_FUNC_EXTERN_TABLE_INDEX, value); }
    set this_ext_idx ( value ) { this.setHeader(this.HEADERS.PARAM1_THIS_EXTERN_TABLE_INDEX, value); }
    set argv_ext_idx ( value ) { this.setHeader(this.HEADERS.PARAM2_ARGV_EXTERN_TABLE_INDEX, value); }
    
    get grow_ext_idx () { return this.getHeader(this.HEADERS.RESULT_GROW_EXTERN_TABLE_INDEX); }
    get func_ext_idx () { return this.getHeader(this.HEADERS.PARAM0_FUNC_EXTERN_TABLE_INDEX); }
    get this_ext_idx () { return this.getHeader(this.HEADERS.PARAM1_THIS_EXTERN_TABLE_INDEX); }
    get argv_ext_idx () { return this.getHeader(this.HEADERS.PARAM2_ARGV_EXTERN_TABLE_INDEX); }
}

export class SetIntegerAtChainOperation extends ChainOperation {

    static HEADERS = this.registerHeaders( "$wasm_setii", {
        PARAM0_TARGET_EXTERN_INDEX : this.headerCount++,
        PARAM1_KEY_UINT32_NUMBER : this.headerCount++,
        PARAM2_VALUE_UINT32_NUMBER : this.headerCount++,
    });

    set target_extern_index ( value ) { this.setHeader(this.HEADERS.PARAM0_TARGET_EXTERN_INDEX, value); }
    set key_uint32_number ( value ) { this.setHeader(this.HEADERS.PARAM1_KEY_UINT32_NUMBER, value); }
    set value_uint32_number ( value ) { this.setHeader(this.HEADERS.PARAM2_VALUE_UINT32_NUMBER, value); }
    
    get target_extern_index () { return this.getHeader(this.HEADERS.PARAM0_TARGET_EXTERN_INDEX); }
    get key_uint32_number () { return this.getHeader(this.HEADERS.PARAM1_KEY_UINT32_NUMBER); }
    get value_uint32_number () { return this.getHeader(this.HEADERS.PARAM2_VALUE_UINT32_NUMBER); }
}

export class SetFuncrefAtChainOperation extends ChainOperation {

    static HEADERS = this.registerHeaders( "$wasm_setif", {
        PARAM0_TARGET_EXTERN_INDEX : this.headerCount++,
        PARAM1_KEY_UINT32_NUMBER : this.headerCount++,
        PARAM2_VALUE_FUNCREF_INDEX : this.headerCount++,
    });

    set target_extern_index ( value ) { this.setHeader(this.HEADERS.PARAM0_TARGET_EXTERN_INDEX, value); }
    set key_uint32_number ( value ) { this.setHeader(this.HEADERS.PARAM1_KEY_UINT32_NUMBER, value); }
    set value_funcref_index ( value ) { this.setHeader(this.HEADERS.PARAM2_VALUE_FUNCREF_INDEX, value); }
    
    get target_extern_index () { return this.getHeader(this.HEADERS.PARAM0_TARGET_EXTERN_INDEX); }
    get key_uint32_number () { return this.getHeader(this.HEADERS.PARAM1_KEY_UINT32_NUMBER); }
    get value_funcref_index () { return this.getHeader(this.HEADERS.PARAM2_VALUE_FUNCREF_INDEX); }
}

export class SetExternrefAtChainOperation extends ChainOperation {

    static HEADERS = this.registerHeaders( "$wasm_setie", {
        PARAM0_TARGET_EXTERN_INDEX : this.headerCount++,
        PARAM1_KEY_UINT32_NUMBER : this.headerCount++,
        PARAM2_VALUE_EXTERN_INDEX : this.headerCount++,
    });

    set target_extern_index ( value ) { this.setHeader(this.HEADERS.PARAM0_TARGET_EXTERN_INDEX, value); }
    set key_uint32_number ( value ) { this.setHeader(this.HEADERS.PARAM1_KEY_UINT32_NUMBER, value); }
    set value_extern_index ( value ) { this.setHeader(this.HEADERS.PARAM2_VALUE_EXTERN_INDEX, value); }
    
    get target_extern_index () { return this.getHeader(this.HEADERS.PARAM0_TARGET_EXTERN_INDEX); }
    get key_uint32_number () { return this.getHeader(this.HEADERS.PARAM1_KEY_UINT32_NUMBER); }
    get value_extern_index () { return this.getHeader(this.HEADERS.PARAM2_VALUE_EXTERN_INDEX); }
}

export class SetBytesFromChainOperation extends ChainOperation {
    static HEADERS = this.registerHeaders( "$wasm_setni", {
        PARAM0_TARGET_EXTERN_INDEX  : this.headerCount++,
        PARAM1_OFFSET_UINT32_NUMBER : this.headerCount++,
        PARAM2_LENGTH_UINT32_NUMBER : this.headerCount++,
        PARAM3_STRIDE_UINT32_NUMBER : this.headerCount++,
    });

    set target_extern_index  ( value ) { this.setHeader(this.HEADERS.PARAM0_TARGET_EXTERN_INDEX, value); }
    set offset_uint32_number ( value ) { this.setHeader(this.HEADERS.PARAM1_OFFSET_UINT32_NUMBER, value); }
    set length_uint32_number ( value ) { this.setHeader(this.HEADERS.PARAM2_LENGTH_UINT32_NUMBER, value); }
    set stride_uint32_number ( value ) { this.setHeader(this.HEADERS.PARAM3_STRIDE_UINT32_NUMBER, value); }
    
    get target_extern_index  () { return this.getHeader(this.HEADERS.PARAM0_TARGET_EXTERN_INDEX); }
    get offset_uint32_number () { return this.getHeader(this.HEADERS.PARAM1_OFFSET_UINT32_NUMBER); }
    get length_uint32_number () { return this.getHeader(this.HEADERS.PARAM2_LENGTH_UINT32_NUMBER); }
    get stride_uint32_number () { return this.getHeader(this.HEADERS.PARAM3_STRIDE_UINT32_NUMBER); }
}

export default (buffer = Buffer.alloc(4)) => 
    wat.module(
        global({name: "self", import: [ "self", "self" ] }, externref),
        global({name: "strf", import: [ "String", "fromCodePoint" ] }, externref),
        global({name: "rget", import: [ "Reflect", "get" ] }, externref),

        func({ name: "self_array", import: ["self", "Array"] }, param(), result(externref)),
        func({ name: "self_apply", import: ["Reflect", "apply"] }, param(externref, externref, externref), result(externref)),
        func({ name: "self_setii", import: ["Reflect", "set"]}, param(externref, i32, i32), result()),
        func({ name: "self_setif", import: ["Reflect", "set"]}, param(externref, i32, funcref), result()),
        func({ name: "self_setie", import: ["Reflect", "set"]}, param(externref, i32, externref), result()),
        
        func({ name: "grow_table"},
            param({ name: "ptr"}, i32),

            i32.store({ offset: GrowTableChainOperation.OFFSET.RESULT_FIRST_EXTERN_INDEX },
                local.get({ name: "ptr" }),
                table.grow({ name: "ext" }, 
                    ref.null(extern), 
                    i32.load({ offset: GrowTableChainOperation.OFFSET.PARAM0_EXTERN_GROW_LENGTH },
                        local.get(0)
                    )
                )
            )
        ),
        func({ name: "copy_memii" },
            param(i32),

            memory.copy(
                i32.load({offset: CopyMemoryChainOperation.OFFSET.PARAM0_DST_WRITER_OFFSET}, local.get(0)),
                i32.load({offset: CopyMemoryChainOperation.OFFSET.PARAM1_SRC_READER_OFFSET}, local.get(0)),
                i32.load({offset: CopyMemoryChainOperation.OFFSET.PARAM2_LEN_MEMCPY_LENGTH}, local.get(0)),
            )
        ),
        func({ name: "wasm_array" },
            param(i32),

            local({name: "result_idx"}, i32),
            local({name: "result_ext"}, externref),

            local.set({name: "result_ext"}, 
                call({name: "self_array"})
            ),

            wat.if(
                local.tee({name: "result_idx"}, 
                    i32.load({offset: NewArrayChainOperation.OFFSET.RESULT_GROW_EXTERN_TABLE_INDEX }, 
                        local.get(0)
                    )
                ),
                wat.then(
                    table.set({name: "ext"}, 
                        local.get({name: "result_idx"}), 
                        local.get({name: "result_ext"}), 
                    )
                ),
                wat.else(
                    i32.store({offset: NewArrayChainOperation.OFFSET.RESULT_GROW_EXTERN_TABLE_INDEX }, 
                        local.get(0),
                        table.grow({name: "ext"}, 
                            local.get({name: "result_ext"}), 
                            i32.const(1)
                        )
                    )
                )
            ),
        ),
        func({ name: "wasm_apply" },
            param(i32),

            local({name: "result_idx"}, i32),
            local({name: "result_ext"}, externref),

            local.set({name: "result_ext"},
                call({ name: "self_apply"},
                    table.get({name: "ext"}, i32.load({offset: ApplyChainOperation.OFFSET.PARAM0_FUNC_EXTERN_TABLE_INDEX}, local.get(0))),
                    table.get({name: "ext"}, i32.load({offset: ApplyChainOperation.OFFSET.PARAM1_THIS_EXTERN_TABLE_INDEX}, local.get(0))),
                    table.get({name: "ext"}, i32.load({offset: ApplyChainOperation.OFFSET.PARAM2_ARGV_EXTERN_TABLE_INDEX}, local.get(0))),
                )
            ),

            wat.if(
                local.tee({name: "result_idx"}, 
                    i32.load({offset: ApplyChainOperation.OFFSET.RESULT_GROW_EXTERN_TABLE_INDEX }, 
                        local.get(0)
                    )
                ),
                wat.then(
                    table.set({name: "ext"}, 
                        local.get({name: "result_idx"}), 
                        local.get({name: "result_ext"}), 
                    )
                ),
                wat.else(
                    i32.store({offset: ApplyChainOperation.OFFSET.RESULT_GROW_EXTERN_TABLE_INDEX }, 
                        local.get(0),
                        table.grow({name: "ext"}, 
                            local.get({name: "result_ext"}), 
                            i32.const(1)
                        )
                    )
                )
            ),
        ),
        func({ name: "wasm_setii" },
            param(i32),
            call({name: "self_setii"},
                table.get({name: "ext"}, i32.load({offset: SetIntegerAtChainOperation.OFFSET.PARAM0_TARGET_EXTERN_INDEX}, local.get(0))),
                i32.load({offset: SetIntegerAtChainOperation.OFFSET.PARAM1_KEY_UINT32_NUMBER}, local.get(0)),
                i32.load({offset: SetIntegerAtChainOperation.OFFSET.PARAM2_VALUE_UINT32_NUMBER}, local.get(0))
            )
        ),
        func({ name: "wasm_setif" },
            param(i32),
            call({ name: "self_setif"},
                table.get({name: "ext"}, i32.load({offset: SetFuncrefAtChainOperation.OFFSET.PARAM0_TARGET_EXTERN_INDEX}, local.get(0))),
                i32.load({offset: SetFuncrefAtChainOperation.OFFSET.PARAM1_KEY_UINT32_NUMBER}, local.get(0)),
                table.get({name: "fun"}, i32.load({offset: SetFuncrefAtChainOperation.OFFSET.PARAM2_VALUE_FUNCREF_INDEX}, local.get(0))),
            )
        ),
        func({ name: "wasm_setie" },
            param(i32),
            call({ name: "self_setie"},
                table.get({name: "ext"}, i32.load({offset: SetExternrefAtChainOperation.OFFSET.PARAM0_TARGET_EXTERN_INDEX}, local.get(0))),
                i32.load({offset: SetExternrefAtChainOperation.OFFSET.PARAM1_KEY_UINT32_NUMBER}, local.get(0)),
                table.get({name: "ext"}, i32.load({offset: SetExternrefAtChainOperation.OFFSET.PARAM2_VALUE_EXTERN_INDEX}, local.get(0))),
            )
        ),
        func({ name: "wasm_setni" },
            param(i32),

            local({name: "tindex"}, i32),
            local({name: "target"}, externref),
            local({name: "offset"}, i32),
            local({name: "length"}, i32),
            local({name: "stride"}, i32),
            local({name: "i"}, i32),

            local.set({name: "tindex"}, i32.load({offset: SetBytesFromChainOperation.OFFSET.PARAM0_TARGET_EXTERN_INDEX}, local.get(0))),
            local.set({name: "offset"}, i32.load({offset: SetBytesFromChainOperation.OFFSET.PARAM1_OFFSET_UINT32_NUMBER}, local.get(0))),
            local.set({name: "length"}, i32.load({offset: SetBytesFromChainOperation.OFFSET.PARAM2_LENGTH_UINT32_NUMBER}, local.get(0))),
            local.set({name: "stride"}, i32.load({offset: SetBytesFromChainOperation.OFFSET.PARAM3_STRIDE_UINT32_NUMBER}, local.get(0))),

            wat.if(
                i32.eqz(local.get({name: "length"})), 
                wat.then(wat.return())
            ),

            local.set({name: "i"}, local.get({name: "length"})),
            local.set({name: "target"}, table.get({name: "ext"}, local.get({name: "tindex"}))),

            loop({name: "i--"},
                local.set({name: "i"}, 
                    i32.sub(local.get({name: "i"}), i32.const(1))
                ),

                call({name: "self_setii"},
                    local.get({name: "target"}),
                    i32.add(
                        local.get({name: "stride"}),
                        local.get({name: "i"}),
                    ),
                    i32.load8_u(
                        i32.add(
                            local.get({name: "offset"}),
                            local.get({name: "i"})
                        )
                    )
                ),
                
                br_if({name: "i--"}, local.get({name: "i"}))
            )
        ),
        
        func({ name: "process_op", export: "process" },
            param(i32),
            local({ name: "fun_index"}, i32),
            local({ name: "op_length"}, i32),

            drop(i32.atomic.rmw.add(i32.const(0), i32.const(1))),

            local.tee({ name: "fun_index" }, i32.atomic.rmw.and({ offset: ChainOperation.OFFSET.CALL_INDIRECT_INDEX }, local.get(0), i32.const(0))),
            wat.if(wat.then(call_indirect({ name: "fun" }, param(i32), local.get(0), local.get({ name: "fun_index" })))),

            local.tee({ name: "op_length" }, i32.atomic.rmw.and({ offset: ChainOperation.OFFSET.BYTES_PER_OPERATION }, local.get(0), i32.const(0))),
            wat.if(wat.then(call({ name: "process_op" }, i32.add(local.get(0), local.get({ name: "op_length" })))))
        ),

        func({ name: "then_bound" },
            param({ name: "caller" }, i32),

            param({ name: "argument0" }, externref),
            param({ name: "argument1" }, externref),
            param({ name: "argument2" }, externref),
            
            local({ name: "ext_count" }, i32),
            local({ name: "tbl_begin" }, i32),
            local({ name: "ptr_start" }, i32),
        ),

        memory(Math.ceil((buffer.byteLength + 16) / 65536) || 1),

        elem(
            table({ name: "ext" }), 
            i32.const(0), 
            externref,

            tbl_ext = [
                ref.null(extern),
                
                global.get(0), 
                global.get(1), 
                global.get(2)
            ]
        ),

        elem(
            table({ name: "fun" }), 
            i32.const(0), 
            funcref,

            tbl_fun = [
                ref.null(func), 
                ref.func({name: "grow_table" /*  1 */ }), 
                ref.func({name: "copy_memii" /*  2 */ }), 
                ref.func({name: "wasm_array" /*  3 */ }), 
                ref.func({name: "wasm_apply" /*  4 */ }), 
                ref.func({name: "wasm_setii" /*  5 */ }), 
                ref.func({name: "wasm_setif" /*  6 */ }), 
                ref.func({name: "wasm_setie" /*  7 */ }), 
                ref.func({name: "wasm_setni" /*  8 */ }), 
                ref.func({name: "process_op" /*  9 */ }), 
                ref.func({name: "then_bound" /* 10 */ }), 
            ]
        ),

        table({ name: "ext" }, tbl_ext.length, 65536, externref),
        table({ name: "fun" }, tbl_fun.length, funcref),

        func({ name: "start" },
            call({ name: "process_op" }, i32.const(16))
        ),

        data(i32.const(16), `"${buffer.toString("hex").replaceAll(/(..)/g, '\\\$1')}"`),

        //start({ name: "start" }),
    );
