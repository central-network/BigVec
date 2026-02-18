import wat, { 
    i32, f32, i64, f64, v128, 
    extern, externref, funcref, shared,
    func, start, type, param, result,
    local, global,
    ref, data, elem, drop,
    table, memory, 
    call, call_indirect, 
    loop, br, br_if, nop, unreachable
} from "./WatProxy.mjs"

export const BYTES_PER_HEADER_VALUE = Uint32Array.BYTES_PER_ELEMENT;

export const HINDEX_OP_CALL_TBL_FUNC_AT = 0;
export const HINDEX_OP_SIZE_BYTE_LENGTH = 1;
export const HCOUNT_OP_REQUIRED_HEADERS = 2;

export const OFFSET_OP_CALL_TBL_FUNC_AT = HINDEX_OP_CALL_TBL_FUNC_AT * BYTES_PER_HEADER_VALUE;
export const OFFSET_OP_SIZE_BYTE_LENGTH = HINDEX_OP_SIZE_BYTE_LENGTH * BYTES_PER_HEADER_VALUE;
export const LENGTH_OP_REQUIRED_HEADERS = 8;

export const OFFSET_OPDATA = LENGTH_OP_REQUIRED_HEADERS;

export const HINDEX_APPLYOP_FUNC_TBLEXT_INDEX = 0 + HCOUNT_OP_REQUIRED_HEADERS;
export const HINDEX_APPLYOP_THIS_TBLEXT_INDEX = 1 + HCOUNT_OP_REQUIRED_HEADERS;
export const HINDEX_APPLYOP_ARGV_TBLEXT_INDEX = 2 + HCOUNT_OP_REQUIRED_HEADERS;
export const HINDEX_APPLYOP_SAVE_TBLEXT_INDEX = 3 + HCOUNT_OP_REQUIRED_HEADERS;
export const HCOUNT_PER_APPLY_OEPRATION = 4 + HCOUNT_OP_REQUIRED_HEADERS;

export const OFFSET_APPLYOP_FUNC_TBLEXT_INDEX = HINDEX_APPLYOP_FUNC_TBLEXT_INDEX * BYTES_PER_HEADER_VALUE;
export const OFFSET_APPLYOP_THIS_TBLEXT_INDEX = HINDEX_APPLYOP_THIS_TBLEXT_INDEX * BYTES_PER_HEADER_VALUE;
export const OFFSET_APPLYOP_ARGV_TBLEXT_INDEX = HINDEX_APPLYOP_ARGV_TBLEXT_INDEX * BYTES_PER_HEADER_VALUE;
export const OFFSET_APPLYOP_SAVE_TBLEXT_INDEX = HINDEX_APPLYOP_SAVE_TBLEXT_INDEX * BYTES_PER_HEADER_VALUE;

export const LENGTH_PER_APPLY_OEPRATION = OFFSET_APPLYOP_SAVE_TBLEXT_INDEX + BYTES_PER_HEADER_VALUE;
export const ELEMENT_OF_APPLY_OEPRATION = 2;

let tbl_ext = [],
    tbl_fun = [];

export class ChainQueue extends Array {
    add () { return this.push(...arguments), this; }
    get buffer () { return Buffer.concat(this.map(o => o.buffer)) }
}

export class ChainOperation {
    static BYTES_PER_OPERATION = LENGTH_OP_REQUIRED_HEADERS;
    static FUNCREF_TABLE_INDEX = 0;

    constructor (
        data_len = new.target.BYTES_PER_OPERATION, 
        func_idx = new.target.FUNCREF_TABLE_INDEX,
        size_extra_alloc = 0
    ) {
        this.length = Math.ceil((data_len+size_extra_alloc)/4)*4;
        this.buffer = Buffer.alloc(this.length);

        this.setHeader(HINDEX_OP_CALL_TBL_FUNC_AT, func_idx);
        this.setHeader(HINDEX_OP_SIZE_BYTE_LENGTH, this.length);
    }

    setHeader (index, value) { this.buffer.writeUint32LE(value, index * BYTES_PER_HEADER_VALUE); }
    getHeader (index) { return this.buffer.readUint32LE(index * BYTES_PER_HEADER_VALUE);}

    static from ( ...args ) {
        const op = new this();
        let hidx = HCOUNT_OP_REQUIRED_HEADERS;
        args.forEach(v => op.setHeader(hidx++, v));
        return op;
    }
}

export class ApplyChainOperation extends ChainOperation {

    static BYTES_PER_OPERATION = LENGTH_PER_APPLY_OEPRATION;
    static FUNCREF_TABLE_INDEX = ELEMENT_OF_APPLY_OEPRATION;

    static from (
        hvalue_func_tblext_index,
        hvalue_this_tblext_index,
        hvalue_argv_tblext_index,
        hvalue_save_tblext_index,        
    ) { return super.from( ...arguments ) }

    set func_tblext_index ( hvalue_func_tblext_index ) { this.setHeader(HINDEX_APPLYOP_FUNC_TBLEXT_INDEX, hvalue_func_tblext_index); }
    set this_tblext_index ( hvalue_this_tblext_index ) { this.setHeader(HINDEX_APPLYOP_THIS_TBLEXT_INDEX, hvalue_this_tblext_index); }
    set argv_tblext_index ( hvalue_argv_tblext_index ) { this.setHeader(HINDEX_APPLYOP_ARGV_TBLEXT_INDEX, hvalue_argv_tblext_index); }
    set save_tblext_index ( hvalue_save_tblext_index ) { this.setHeader(HINDEX_APPLYOP_ARGV_TBLEXT_INDEX, hvalue_save_tblext_index); }
    
    get func_tblext_index () { return this.getHeader(HINDEX_APPLYOP_FUNC_TBLEXT_INDEX); }
    get this_tblext_index () { return this.getHeader(HINDEX_APPLYOP_THIS_TBLEXT_INDEX); }
    get argv_tblext_index () { return this.getHeader(HINDEX_APPLYOP_ARGV_TBLEXT_INDEX); }
    get save_tblext_index () { return this.getHeader(HINDEX_APPLYOP_ARGV_TBLEXT_INDEX); }
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

            i32.store({ offset: OFFSET_OPDATA },
                local.get({ name: "ptr" }),
                table.grow({ name: "ext" }, ref.null(extern), i32.const(1))
            )
        ),
        func({ name: "wasm_array" },
            param(i32),
            table.set({name: "ext"},
                i32.load({offset: OFFSET_OPDATA}, local.get(0)),
                call({name: "self_array"})
            )
        ),
        func({ name: "wasm_apply" },
            param(i32),
            table.set({name: "ext"},
                i32.load({offset: OFFSET_APPLYOP_SAVE_TBLEXT_INDEX}, local.get(0)),
                call({ name: "self_apply"},
                    table.get({name: "ext"}, i32.load({offset: OFFSET_APPLYOP_FUNC_TBLEXT_INDEX}, local.get(0))),
                    table.get({name: "ext"}, i32.load({offset: OFFSET_APPLYOP_THIS_TBLEXT_INDEX}, local.get(0))),
                    table.get({name: "ext"}, i32.load({offset: OFFSET_APPLYOP_ARGV_TBLEXT_INDEX}, local.get(0))),
                )
            )
        ),
        func({ name: "wasm_setii" },
            param(i32),
            call({ name: "self_setii"},
                table.get({name: "ext"}, i32.load({offset: 12}, local.get(0))),
                i32.load({offset: 16}, local.get(0)),
                i32.load({offset: 20}, local.get(0))
            )
        ),
        func({ name: "wasm_setif" },
            param(i32),
            call({ name: "self_setif"},
                table.get({name: "ext"}, i32.load({offset: 12}, local.get(0))),
                i32.load({offset: 16}, local.get(0)),
                table.get({name: "fun"}, i32.load({offset: 20}, local.get(0))),
            )
        ),
        func({ name: "wasm_setie" },
            param(i32),
            call({ name: "self_setie"},
                table.get({name: "ext"}, i32.load({offset: 12}, local.get(0))),
                i32.load({offset: 16}, local.get(0)),
                table.get({name: "ext"}, i32.load({offset: 20}, local.get(0))),
            )
        ),
        func({ name: "wasm_setni" },
            param(i32),

            local({name: "target"}, externref),
            local({name: "offset"}, i32),
            local({name: "length"}, i32),
            local({name: "stride"}, i32),
            local({name: "i"}, i32),

            local.set({name: "target"}, table.get({name: "ext"}, i32.load({offset: 12}, local.get(0)))),
            local.set({name: "offset"}, i32.load({offset: 16}, local.get(0))),
            local.set({name: "length"}, i32.load({offset: 20}, local.get(0))),
            local.set({name: "stride"}, i32.load({offset: 24}, local.get(0))),

            wat.if(local.get({name: "length"}),
                wat.then(local.set({name: "i"}, local.get({name: "length"}))),
                wat.else(wat.return())
            ),

            loop({name: "i--"},
                local.set({name: "i"}, 
                    i32.sub(
                        local.get({name: "i"}),
                        i32.const(-1) 
                    )
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
        func({ name: "copy_memii" },
            param(i32),
            memory.copy(
                i32.load({offset: 12}, local.get(0)),
                i32.load({offset: 16}, local.get(0)),
                i32.load({offset: 20}, local.get(0)),
            )
        ),
        func({ name: "process_op", export: "process" },
            param(i32),
            local({ name: "fun_index"}, i32),
            local({ name: "op_length"}, i32),

            drop(i32.atomic.rmw.add(i32.const(0), i32.const(1))),

            local.tee({ name: "fun_index" }, i32.atomic.rmw.and({ offset: OFFSET_OP_CALL_TBL_FUNC_AT }, local.get(0), i32.const(0))),
            wat.if(wat.then(call_indirect({ name: "fun" }, param(i32), local.get(0), local.get({ name: "fun_index" })))),

            local.tee({ name: "op_length" }, i32.atomic.rmw.and({ offset: OFFSET_OP_SIZE_BYTE_LENGTH }, local.get(0), i32.const(0))),
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
                
                ref.func({name: "wasm_array" /*  1 */ }), 
                ref.func({name: "wasm_apply" /*  2 */ }), 
                ref.func({name: "wasm_setie" /*  3 */ }), 
                ref.func({name: "wasm_setif" /*  4 */ }), 
                ref.func({name: "wasm_setii" /*  5 */ }), 
                ref.func({name: "wasm_setni" /*  6 */ }), 

                ref.func({name: "process_op" /*  7 */ }), 
                ref.func({name: "then_bound" /*  8 */ }), 
                ref.func({name: "copy_memii" /*  9 */ }), 
                ref.func({name: "grow_table" /* 10 */ }), 
            ]
        ),

        table({ name: "ext" }, tbl_ext.length, 65536, externref),
        table({ name: "fun" }, tbl_fun.length, funcref),

        func({ name: "start" },
            call({ name: "process_op" }, i32.const(16))
        ),

        data(i32.const(16), `"${buffer.toString("hex").replaceAll(/(..)/g, '\\\$1')}"`),

        start({ name: "start" }),
    );
