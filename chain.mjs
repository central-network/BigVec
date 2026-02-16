
import fs from "fs";
import cp from "child_process";


const WASM_TEMPLATE = String(`
(module
  (import "self" "self"             (global $self externref))
  (import "String" "fromCodePoint"  (global $self_String_fromCodePoint externref))
  (import "Reflect" "get"           (global $self_Reflect_get externref))

  (import "self" "Array"            (func $self_array (result externref)))
  (import "Reflect" "set"           (func $self_set_eii (param externref i32 i32)))
  (import "Reflect" "set"           (func $self_set_eie (param externref i32 externref)))
  (import "Reflect" "set"           (func $self_set_eif (param externref i32 funcref)))
  (import "Reflect" "apply"         (func $self_apply (param externref externref externref) (result externref)))
  
  (import "console" "warn"         (func $warnife (param i32 funcref externref) (result)))
  (import "console" "warn"         (func $warniii (param i32 i32 i32) (result)))
  (import "console" "log"         (func $logiii (param i32 i32 i32) (result)))
  (import "console" "warn"         (func $warniie (param i32 i32 externref) (result)))
  (import "console" "warn"         (func $logeii (param i32 i32 externref) (result)))

  (;CHAIN_DATA;)

  (table $ext 4 65536 externref)
  (table $fun 11 funcref)
  
  (elem (table $ext) (i32.const 1) externref (global.get 0) (global.get 1) (global.get 2))
  (elem (table $fun) (i32.const 1) $wasm_array $wasm_set_eii $wasm_set_eie $wasm_set_eif $wasm_apply $copy $copyInto $callback $drop $grow)

  (global $ptr (mut i32) (i32.const 0))

  (func $grow
    (param $ptr i32)
    
    (i32.store offset=12 
      (local.get $ptr) 
      (table.grow $ext 
        (ref.null extern) 
        (i32.load offset=12 (local.get $ptr))
      )
    )
  )

  (func $wasm_array
    (param $ptr i32)

    (table.set $ext 
        (i32.load offset=12 (local.get $ptr))
        (call $self_array)
    )
  )
  
  (func $wasm_set_eii
    (param $ptr i32)

    (call $self_set_eii
      (table.get $ext (i32.load offset=12 (local.get $ptr)))
      (i32.load offset=16 (local.get $ptr))
      (i32.load offset=20 (local.get $ptr))
    )
  )

  (func $wasm_set_eie
    (param $ptr i32)

    (call $self_set_eie
      (table.get $ext (i32.load offset=12 (local.get $ptr)))
      (i32.load offset=16 (local.get $ptr))                       
      (table.get $ext (i32.load offset=20 (local.get $ptr))) 
    )
  )
  
  (func $wasm_set_eif
    (param $ptr i32)

    (call $self_set_eif
      (table.get $ext (i32.load offset=12 (local.get $ptr)))
      (i32.load offset=16 (local.get $ptr))
      (table.get $fun (i32.load offset=20 (local.get $ptr)))
    )
  )

  (func $wasm_apply
    (param $ptr i32)

    (table.set $ext 
        (i32.load offset=24 (local.get $ptr))
        (call $self_apply
          (table.get $ext (i32.load offset=12 (local.get $ptr))) 
          (table.get $ext (i32.load offset=16 (local.get $ptr))) 
          (table.get $ext (i32.load offset=20 (local.get $ptr))) 
        ) 
    )
  )

  (func $copy
    (param $ptr i32)
    (memory.copy
      (i32.load offset=16 (local.get $ptr))
      (i32.load offset=12 (local.get $ptr))
      (i32.load offset=20 (local.get $ptr))
    )
  )

  (func $copyInto
    (param $ptr               i32)
    (local $target      externref)
    (local $offset            i32)
    (local $length            i32)
    (local $begin             i32)
    (local $i                 i32)

    (local.set $target (table.get $ext (i32.load offset=12 (local.get $ptr))))
    (local.set $offset (i32.load offset=16 (local.get $ptr)))
    (local.set $begin  (i32.load offset=24 (local.get $ptr)))
    (local.tee $length (i32.load offset=20 (local.get $ptr)))

    (if (i32.eqz (local.tee $i)) (then return))
    
    (loop $i--
      (local.tee $i (; br_if ;) (i32.sub (local.get $i) (i32.const 1)))
      (call $self_set_eii
        (local.get $target)
        (i32.add (local.get $begin) (local.get $i))
        (i32.load8_u (i32.add (local.get $offset) (local.get $i)))
      )
      (br_if $i--)
    )
  )

  (func $drop
    (param $ptr i32)
    (table.set $ext (i32.load offset=12 (local.get $ptr)) (ref.null extern))
  )

  (func $callback
    (param $ptr i32)
    (param externref externref externref)
    
    (local $ext_count i32)
    (local $ext_begin i32)
    (local $ptr_chain i32)

    (call $warniie
        (local.get 0)
        (i32.load (local.get 0))
        (local.get 1)
    )

    (return)
    
    (local.set $ext_count (i32.load offset=12 (local.get $ptr)))
    (local.set $ext_begin (i32.load offset=16 (local.get $ptr)))

    (block $args
        (br_if $args (i32.lt_u (local.get $ext_count) (i32.const 1)))
        (table.set $ext (i32.add (local.get $ext_begin) (i32.const 0)) (local.get 1))

        (br_if $args (i32.lt_u (local.get $ext_count) (i32.const 2)))
        (table.set $ext (i32.add (local.get $ext_begin) (i32.const 1)) (local.get 2))

        (br_if $args (i32.lt_u (local.get $ext_count) (i32.const 3)))
        (table.set $ext (i32.add (local.get $ext_begin) (i32.const 2)) (local.get 3))
    )

    (local.tee $ptr_chain (i32.load offset=20 (local.get $ptr)))
    (if (then (call $process (local.get $ptr_chain))))
  )

  (func $process
    (param $ptr i32)
    (local $fun i32)
    (local $len i32)

    (loop $chain
      (local.tee $fun (i32.load offset=8 (local.get $ptr)))
      (if (then (call_indirect $fun (param i32) (local.get $ptr) (local.get $fun))))

      (local.tee $len (i32.load offset=4 (local.get $ptr)))
      (if (then (br $chain (local.set $ptr (i32.add (local.get $ptr) (local.get $len))) )))
    )
  )
  
  (func $start 
    (call $process (i32.const 0))
  )

  (start $start) 

  (export "process" (func $process))
)
`);

// Helper class for a single chain operation
export class Operation {
    constructor(id, type, size, funcIndex, chain, writePayloadFn) {
        this.id = id;
        this.type = type;
        this.size = size; // Payload size
        this.funcIndex = funcIndex;
        this.writePayloadFn = writePayloadFn; // Function to write payload to view
        this.offset = 0; // Will be calculated
        this.tableIdx = -1; // Predicted externref table index (if applicable)
        this.chain_id = chain.chain_id; // Predicted externref table index (if applicable)
        this.data = null;
        this.buffer = null;

        Object.defineProperties(this, {
            drop : { value: function () { chain.drop(this.tableIdx) } }
        })

        return new Proxy(this, {
            get : (target, prop, prx) => {
                if (Reflect.has(target, prop) === false) {
                    return chain.self.Reflect.get(this, prop);
                }

                return Reflect.get(target, prop);
            }
        });
    }
}


const [ offset, $funs, elem_$fun = Object.fromEntries($funs.trim().split(/[\$|\s]/g).filter(Boolean).map((fn, i) => [fn, i+ +offset]))
] = Array.from(WASM_TEMPLATE.match(/\(elem\s+\(table\s+\$fun\)\s+\(i32\.const\s+(\d+)\)\s+(.*)\)/m)).slice(1);

export default class ChainBuilder {
    constructor() {
        this.ops = [];
        this.opCounter = 0;

        this.chain_id = 0;
        this.tbl_idx = 4;
        this.symbolMap = new Map([
            ["$null", 0],
            ["$self", 1],
            ["$self.String.fromCodePoint", 2],
            ["$self.Reflect.get", 3]
        ]);

        // Track imports for Interset Module
        this.interset = {
            externs: [ // Table index -> Symbol Name
                "$null", 
                "$self", 
                "$self.String.fromCodePoint", 
                "$self.Reflect.get"
            ],
            funcs: [ // Table index -> Symbol Name (func)
                "$void0" // Index 0 is typically void/null
            ]
        };

        this.functions = {
            ...elem_$fun, end: 0
            /*
            end: 0,
            wasm_array: 1,
            wasm_set_eii: 2,
            wasm_set_eie: 3,
            wasm_set_eif: 4,
            wasm_apply: 5,
            copy: 6,
            copyInto: 7,
            callback: 8,
            drop: 9,
            grow: 10,
            */
        };

        this.init_standard_library();
        this.define_exotic_values();
    }

    define_exotic_values () {
        this.exoticValueSet = new Set();
        this.exoticValueMap = new Map();

        Array.of(
            true, false, null, 'NaN', undefined, '∞', '-∞',
            -Infinity, +Infinity, '-0', 0, '0n', '1n', '-1n', ""
        ).forEach(ev => this.exoticValueSet.add(ev))
    }

    is_exotic (value) {
        return this.exoticValueSet?.has( 
            this.swap_exotic_value(value) 
        );
    }

    swap_exotic_value (value) {
        if (typeof value === 'number') {
            if (isNaN(value)) { return 'NaN';}
            if (value.toLocaleString() === '-0') { return '-0';}
        }

        if (typeof value === 'bigint') {
            switch (Number(value)) {
                case  0: return  '0n';
                case  1: return  '1n';
                case -1: return '-1n';
                default: return value;
            }            
        }

        switch (`${value}`) {
            case 'true':      return true;
            case 'false':     return false;
            case 'null':      return null;
            case 'undefined': return undefined;
            case '∞':         return +Infinity;
            case '-∞':        return -Infinity;
            case '-Infinity': return -Infinity;
            case '+Infinity': return +Infinity;
            case '0':         return 0;
            case '""':        
            case "''": 
            case "``":        return "";
            default:          return value;
        }
    }

    get_exotic_extern_idx (value) {
        value = this.swap_exotic_value(value);

        if (this.is_exotic(value) === false) {
            throw [`this is not an exotic value:`, value];
        }
        
        if (this.exoticValueMap.has(value) === true) {
            return this.exoticValueMap.get(value);
        }

        switch (value) {
            case null:      this.exoticValueMap.set(value, 0);                                   break;
            case 'NaN':     this.exoticValueMap.set(value, this.$self.parseInt().tableIdx); break;
            case undefined: this.exoticValueMap.set(value, this.resolve_path('self.undefined').tableIdx);       break;
            case true:      this.exoticValueMap.set(value, this.resolve_path('self.true').tableIdx);            break;
            case false:     this.exoticValueMap.set(value, this.resolve_path('self.false').tableIdx);           break;
            case '-0':      this.exoticValueMap.set(value, this.$self.parseInt('-0x0').tableIdx);break;
            case 0:         this.exoticValueMap.set(value, this.$self.parseInt('+0x0').tableIdx);break;
            case -Infinity: this.exoticValueMap.set(value, this.resolve_path('self.Number.NEGATIVE_INFINITY').tableIdx); break;
            case +Infinity: this.exoticValueMap.set(value, this.resolve_path('self.Number.POSITIVE_INFINITY').tableIdx); break;
            case '0n':      this.exoticValueMap.set(value, this.$self.BigInt(0).tableIdx);       break;
            case '1n':      this.exoticValueMap.set(value, this.$self.BigInt(1).tableIdx);       break;
            case '-1n':     this.exoticValueMap.set(value, this.$self.BigInt(-1).tableIdx);      break;
            case "":        this.exoticValueMap.set(value, this.$self.String().tableIdx);        break;
        }

        return this.exoticValueMap.get(value);
    }

    createInnerChain (callback) {
    }

    addOp(type, size, funcIndex, writePayloadFn, needGrow) {

        const id = `op_${this.opCounter++}`;
        const op = new Operation(id, type, size, funcIndex, this, writePayloadFn);

        if (needGrow) {
            const growOp = this.grow(needGrow);

            op.tableIdx = 
            growOp.tableIdx = this.tbl_idx++;

            this.ops.push(op);

            if (type === 'array') {
                this.copy(growOp, op, 0, 4, 12);
            }

            if (type === 'apply') {
                this.copy(growOp, op, 12, 4, 12);
            } 
             
        } else {

            this.ops.push(op);
        }
        

        return op;
    }

    alloc(payloadSize) {
        const op = this.addOp('alloc', payloadSize, 0, (view, offset) => {
             for(let i=0; i<payloadSize; i++) view.setUint8(offset+i, 0);
        });
        return op;
    }
    
    create_value(val) {
        const op = this.addOp('value', 4, 0, (view, offset) => {
            view.setInt32(offset, val, true);
        });
        return op;
    }
    
    get_externref(key) {
        if (!this.symbolMap.has(key)) {
            throw new Error(`Symbol '${key}' not found in symbol map.`);
        }
        return this.create_value(this.symbolMap.get(key));
    }
    
    register_externref(key, op) {
        this.symbolMap.set(key, op.tableIdx);
        this.interset.externs[op.tableIdx] = key;
    }

    wasm_array() {
        return this.addOp('array', 4, this.functions.wasm_array, (view, offset) => {
            view.setInt32(offset, 0, true); 
        }, true);
    }

    drop(tableIdxOrOperation) {
        let tableIdx = tableIdxOrOperation;

        if (tableIdxOrOperation instanceof Operation) {
            tableIdx = tableIdxOrOperation.tableIdx;
        }

        if (tableIdx < 1) { 
            tableIdx = 0;
        }

        return this.addOp('drop', 4, this.functions.drop, (view, offset) => {
            view.setInt32(offset, tableIdx, true); 
        });
    }

    grow(count = 1) {
        return this.addOp('grow', 4, this.functions.grow, (view, offset) => {
            view.setInt32(offset, count, true); 
        });
    }
    
    wasm_apply(func, thisArg, argsList) {
        return this.addOp('apply', 16, this.functions.wasm_apply, (view, offset) => {
            view.setInt32(offset, func, true);
            view.setInt32(offset+4, thisArg, true);
            view.setInt32(offset+8, argsList, true);
            view.setInt32(offset+12, 0, true); // Result
        }, true);
    }

    apply (opFunc, thisArg, argsList) {
        if (false === argsList instanceof Operation) {
            argsList = this.make_args(argsList);
        }

        if (false === opFunc instanceof Operation) {
            opFunc = this.resolve_path(`${opFunc}`);
        }

        const op = this.apply_func(opFunc, thisArg, argsList);

        return op;
    }

    construct(constructor, argsList = []) {

        if (false === constructor instanceof Operation) {
            constructor = this.resolve_path(`${constructor}`);
        }

        const opFunc = this.$self.Reflect.construct;
        const opThis = null;
        const opArgs = this.make_args([constructor, argsList]);
        
        return this.apply_func(opFunc, opThis, opArgs);
    }

    get self () { return this.path_resolver_proxy(); }

    get $self () {        
        return this.path_resolver_proxy(); 
    }

    isProxyPath (any) {
        return this.proxies.has(any);
    }

    proxies = new WeakSet

    path_resolver_proxy (path = "self") {
        const prx = new Proxy(new Function, {
            apply : (obj, thisArg, argsList, a) => {
                if (this.isProxyPath(thisArg)) {
                    thisArg = this.resolve_path(
                        thisArg.toString()
                    );
                }
                return this.apply(path, thisArg, argsList)
            },

            construct: (obj, argsList) => {
                return this.construct(path, argsList);
            },

            get : (obj, key, prx) => {
                if (key === Symbol.toPrimitive || key === 'toString') {
                    return () => path;
                }

                if (key === "tableIdx") {
                    return this.symbolMap.get(`$${path}`);
                }

                if (key === "drop" && !path.endsWith("prototype")) {
                    return () => this.drop(prx.tableIdx);
                }

                if (key === "bind" && !path.endsWith("Function")) {
                    return this.bind_function.bind(this, path);
                }

                if (key === "call" && !path.endsWith("Function")) {
                    return (thisArg, ...argsList) => {
                        return this.apply(path, thisArg, argsList
                        )
                    };
                }

                if (key === "apply") {
                    if (path.endsWith("Reflect")) {
                        path = this.resolve_path('self.Reflect.apply');
                    }

                    return (thisArg, argsList) => {
                        return this.apply(path, thisArg, argsList)
                    };
                }

                return this.path_resolver_proxy(
                    path.concat(".", key)
                );
            }
        });

        this.proxies.add(prx);

        return prx;
    }
    
    copyInto(objIndexOrAddress, offset, length, begin = 0) {

        const op = this.addOp('set_nu8', 16, this.functions.copyInto, (view, _offset) => {
             view.setInt32(_offset, objIndexOrAddress, true);     
             view.setInt32(_offset + 4, offset, true);     
             view.setInt32(_offset + 8, length, true);       
             view.setInt32(_offset + 12, begin, true);       
        });

        if (objIndexOrAddress instanceof Operation) {
            this.copy(objIndexOrAddress, op, 0, 4);
        }

        return op;
    }

    copyFrom (source) {
        const data = Buffer.from(source);
        const byteLength = data.byteLength;

        const $buffer = new this.$self.ArrayBuffer(byteLength);
        const $bufferView = new this.$self.Uint8Array($buffer);
        const opHeadersLength = 16;
        
        let totalAllocSize = opHeadersLength + byteLength;
        if (totalAllocSize % 16) {
            totalAllocSize = (totalAllocSize + 16) - (totalAllocSize % 16);
        }
        
        const op = this.addOp('alloc', totalAllocSize, this.functions.copyInto, (view, offset) => {            
            view.setInt32(offset, $bufferView.tableIdx, true);
            view.setInt32(offset + 4, offset + opHeadersLength, true);
            view.setInt32(offset + 8, byteLength, true);
            view.setInt32(offset + 12, 0, true);
        });

        $buffer.data = data;
        op.buffer = $buffer;

        return $buffer;
    }
    
    wasm_set_any (obj, key, val) {
        if (obj instanceof Operation && obj.tableIdx > -1) {
            obj = obj.tableIdx;
        }
        if (Array.isArray(val)) {
            return this.wasm_set_eie(obj, key, this.make_args(val).tableIdx);
        }

        if (this.isProxyPath(val)) {
            val = this.resolve_path(val.toString());
        }

        if (val !== Object(val)) {
            if (typeof val === "symbol")  {
                let sym = val, set;

                if (this.symbolMap.has(sym) === false) {
                    const wellKnownDescription = Object
                        .getOwnPropertyNames(Symbol)
                        .filter(n => typeof Symbol[n] === 'symbol')
                        .find(n => Symbol[n] === sym);
                    
                    if (wellKnownDescription) {
                        sym = this.resolve_path(`$self.Symbol.${wellKnownDescription}`);
                    }
                    else {
                        sym = this.$self.Symbol.for(val.description);
                    }
                    
                    this.symbolMap.set(val, sym);
                }

                sym = this.symbolMap.get(val).tableIdx;

                return this.wasm_set_eie(obj,key,sym);
            }

            if (this.is_exotic(val)) {
                val = this.get_exotic_extern_idx(val);
                return this.wasm_set_eie(obj, key, val); 
            }

            if (typeof val === "number")  {
                val = this.$self.Number(val.toString()).tableIdx;
                return this.wasm_set_eie(obj, key, val); 
            }

            if (typeof val === "bigint")  {
                val = this.$self.BigInt(val.toString()).tableIdx;
                return this.wasm_set_eie(obj, key, val); 
            }

            if (typeof val === "string")  {
                val = this.create_string(val).tableIdx;
                return this.wasm_set_eie(obj, key, val); 
            }
        }

        if (val instanceof Operation) {
            if (val.funcIndex === this.functions.callback) {
                return this.wasm_set_eif(obj, key, val.funcIndex);
            }

            if (val.tableIdx > -1) {
                return this.wasm_set_eie(obj, key, val.tableIdx);
            }
        }

        const set = this.wasm_set_eie(obj,key,0);
        this.copy(val, set, 8, 4);
        return set;
    }

    
    wasm_set_eie(obj, key, val) {
        const op = this.addOp('set_ext', 12, this.functions.wasm_set_eie, (view, offset) => {
            view.setInt32(offset, obj, true);
            view.setInt32(offset+4, key, true);
            view.setInt32(offset+8, val, true);
        });
        return op;
    }

    wasm_set_eii(objIndexOrAddress, key, value) {
        const op = this.addOp('set_i32', 12, this.functions.wasm_set_eii, (view, offset) => {
             view.setInt32(offset, objIndexOrAddress, true); 
             view.setInt32(offset + 4, key, true);     
             view.setInt32(offset + 8, value, true);       
        });
        return op;
    }

    wasm_set_eif(obj, key, val) {
        const op = this.addOp('set_fun', 12, this.functions.wasm_set_eif, (view, offset) => {
            view.setInt32(offset, obj, true);
            view.setInt32(offset+4, key, true);
            view.setInt32(offset+8, val, true);
        });
        return op;
    }
    
    copy(srcOp, dstOp, dstOffset, length, srcInnerOffset) {
        const idx = this.ops.indexOf(dstOp);
        if (idx === -1) throw new Error("Target operation not found in chain");

        const op = new Operation(`op_${this.opCounter++}`, 'copy', 12, this.functions.copy, this, (view, offset, op, resolveFn) => {
            srcInnerOffset ??=  (srcOp.type === 'apply') ? 24 : 
                                (srcOp.type === 'array') ? 12 : 
                                (srcOp.type === 'value') ? 12 : 
                                (srcOp.type === 'alloc') ? 12 : 
                                12; 

            const srcAddr = resolveFn(srcOp) + srcInnerOffset;
            const dstAddr = resolveFn(dstOp) + 12 + dstOffset; 
            
            view.setInt32(offset, srcAddr, true);
            view.setInt32(offset + 4, dstAddr, true);
            view.setInt32(offset + 8, length, true);
        });
        
        this.ops.splice(idx, 0, op);
        return op;
    }
    
    create_string(str) {
        if (this.symbolMap.has(str)) {
             return this.get_externref(str); 
        }

        const opArgs = this.wasm_array();
        const codePoints = [...str].map(c => c.codePointAt(0));

        codePoints.forEach((code, index) => {
            this.wasm_set_eii(opArgs.tableIdx, index, code);
        });
        
        const opApply = this.wasm_apply(0, 0, opArgs.tableIdx);
        const opFunc = this.get_externref("$self.String.fromCodePoint");
        
        this.copy(opFunc, opApply, 0, 4);
        
        this.symbolMap.set(str, opApply.tableIdx);
        
        return opApply;
    }

    make_args(items) {
        const opArr = this.wasm_array();
        
        items.forEach((value, index) => {
            this.wasm_set_any(opArr, index, value);
        });
        
        return opArr;
    }

    apply_func(funcOp, thisOp, argsOp) {
        const opApply = this.wasm_apply(0, 0, 0);

        if (false === funcOp instanceof Operation) {
            funcOp = this.resolve_path(`${funcOp}`);
        }

        this.copy(funcOp, opApply, 0, 4);
        
        if (thisOp) {
             this.copy(thisOp, opApply, 4, 4);
        } else {
             const opNull = this.get_externref("$null");
             this.copy(opNull, opApply, 4, 4);
        }
        
        this.copy(argsOp, opApply, 8, 4);
        return opApply;
    }

    resolve_path(path) {
        if (path.startsWith("self")) { path = `$${path}`; }
        if (this.symbolMap.has(path)) return this.get_externref(path);
        
        const parts = path.split('.');
        if (parts[0] !== '$self') throw new Error("Path must start with $self");
        
        let currentPath = '$self';
        let currentOp = this.get_externref('$self');
        
        for (let i = 1; i < parts.length; i++) {
            let part = parts[i];
            let descriptorMode = null;
            
            if (i === parts.length - 1) {
                const match = part.match(/(.*)\[(get|set|value)\]$/);
                if (match) {
                    part = match[1];
                    descriptorMode = match[2];
                }
            }
            
            const nextPath = descriptorMode ? `${currentPath}.${part}[${descriptorMode}]` : `${currentPath}.${part}`;
            
            if (this.symbolMap.has(nextPath)) {
                currentOp = this.get_externref(nextPath);
            } else {
                const opPropName = this.create_string(part);
                
                if (descriptorMode) {
                    const opFuncDesc = this.get_externref("$self.Reflect.getOwnPropertyDescriptor");
                    const opArgsDesc = this.make_args([currentOp, opPropName]);
                    
                    const opDesc = this.apply_func(opFuncDesc, null, opArgsDesc);
                    
                    const opFieldStr = this.create_string(descriptorMode);
                    const opFuncGet = this.get_externref("$self.Reflect.get");
                    const opArgsGet = this.make_args([opDesc, opFieldStr]);
                    
                    const opResult = this.apply_func(opFuncGet, null, opArgsGet);
                    
                    this.register_externref(nextPath, opResult);
                    currentOp = opResult;
                    
                } else {
                    const opFuncGet = this.get_externref("$self.Reflect.get");
                    const opArgsGet = this.make_args([currentOp, opPropName]);
                    
                    const opResult = this.apply_func(opFuncGet, null, opArgsGet);
                    
                    this.register_externref(nextPath, opResult);
                    currentOp = opResult;
                }
            }
            currentPath = nextPath;
        }
        return currentOp;
    }

    init_standard_library() {
        this.resolve_path("$self.Reflect.getOwnPropertyDescriptor");

        const standardLib = [
            "$self.Reflect.construct",
            "$self.Function.bind",
            "$self.Function.call",
            "$self.Uint8Array",
            "$self.WebAssembly.compile",
            "$self.WebAssembly.instantiate",
            "$self.WebAssembly.Instance.prototype.exports[get]",
            "$self.WebAssembly.Memory.prototype.buffer[get]",
            "$self.WebAssembly.Table.prototype.get",
            "$self.WebAssembly.Table.prototype.set",
            "$self.Promise.prototype.then",
            "$self.Promise.prototype.catch",
        ];
        
        for(const path of standardLib) {
            this.resolve_path(path);
        }
    }

    bind_function(path, ...args) {
        return this.$self.Reflect.apply(
            null, [ 
                this.resolve_path('$self.Function.bind'), 
                this.resolve_path(path), args
            ]
        )
    }

    /*
     * EXPERIMENTAL: New method to track function bindings for Interset
     */
    register_function(funcPath) {
        // Just a placeholder to ensure it goes into the funcs list if we need it explicitly
        // Currently bind_function returns an OP that puts result in EXTERNREF table (as it is a bound function object).
        // But if we want to put it in FUNCREF table, we need a way to say "This is a function".
        // The user says: 
        // [ (ref.null func), (ref.func $void0), (ref.func $self.Navigator.prototype.gpu[get].call) ]
        // This implies the *source* of the function is identified.
        
        const idx = this.interset.funcs.length;
        this.interset.funcs.push(funcPath);
        return idx; 
    }


    end() {
        this.endOp = this.addOp('end', 0, this.functions.end, () => {});
    }

    resolve() {
        const funcs = new Map(Object.keys(this.functions).map(funcName => [ this.functions[funcName], funcName ]));

        let currentOffset = 0;
        for (const op of this.ops) {
            op.offset = currentOffset;
            currentOffset += (12 + op.size);
        }
        
        const totalSize = currentOffset;
        const buffer = new Uint8Array(totalSize);
        const view = new DataView(buffer.buffer);

        
        let prevPtr = 0; 
        const getAddr = (op) => 0 + op.offset; 


        for (const op of this.ops) {
            const opStart = op.offset;
            
            Object.defineProperties(op, {
                offset        : { enumerable: true, value: op.offset },
                dataOffset    : { enumerable: true, value: op.offset + 12 },
                setDataHeader : { enumerable: false, value: function (index, value) { view.setInt32(this.dataOffset + (index * 4), value, true); }},
                getDataHeader : { enumerable: false, value: function (index) { return view.getInt32(this.dataOffset + (index * 4), true); }},
                setHeader     : { enumerable: false, value: function (index, value) { view.setInt32(this.offset + (index * 4), value, true); }},
                getHeader     : { enumerable: false, value: function (index) { return view.getInt32(this.offset + (index * 4), true); }},
                writeData     : { enumerable: false, value: function (payload) { return Buffer.from(payload).copy(buffer, this.dataOffset); }},
                getAllHeaders : { enumerable: false, value: function () { 
                    return new Map([ 
                        ["offset", this.offset ],
                        ["prevPtr", this.getHeader(0) ],
                        ["chainLen", this.getHeader(1) ],
                        ["funcIndex", this.getHeader(2) ],
                        ["function", funcs.get(this.getHeader(2) || -1) ],
                        ["opHeaders", new Array(this.size/4).fill().map((v,i) => this.getDataHeader(i)) ],
                    ]); 
                } },
            });

            view.setInt32(opStart + 0, prevPtr, true);
            view.setInt32(opStart + 4, 12 + op.size, true);
            view.setInt32(opStart + 8, op.funcIndex, true);
            
            if (typeof op.writePayloadFn === "function") {
                op.writePayloadFn(view, op.dataOffset, op, (targetOp) => getAddr(targetOp));
            }
            
            if (op.buffer || op.data) { 
                let data = Buffer.from(op.data || op.buffer.data),
                    dataLength = data.byteLength,
                    viewOffset = view.getInt32(op.offset + 16, true),
                    viewLength = view.getInt32(op.offset + 20, true),
                    dataOffset = view.getInt32(op.offset + 24, true),
                    copyLength = Math.min(dataLength, viewLength);

                while (copyLength--) {
                    view.setUint8(viewOffset++, data.readUint8(dataOffset++));
                }                    
            };

            prevPtr = getAddr(op);
        }
        return buffer;
    }

    get_link_imports() {
        // [ [externs...], [funcs...] ]
        return [
            this.interset.externs,
            this.interset.funcs
        ];
    }

    getHex() {    
        this.endOp ??= this.end();    
        const buffer = this.resolve();
        return Array.from(buffer)
            .map(b => b.toString(16).padStart(2, '0'))
            .join('').replaceAll(/(..)/g, '\\$1');
    }
    
    // Writes the final WASM file to disk
    writeFile(path) {
        
        const hexIdx = this.getHex();
        const wat = WASM_TEMPLATE
            .replace("(;CHAIN_DATA;)", `
            (memory ${Math.ceil(hexIdx.length/(3*65536))})
            (data (i32.const 0) "${hexIdx}")`);

        // Use a temporary file for WAT to avoid clutter, or assume user handles intermediate WAT if they want
        // But here we need to compile it.
        // Let's write WAT to a temp location, then compile to the target path.
        const tempWatPath = path.replace('.wasm', '.wat');
        fs.writeFileSync(tempWatPath, wat);
        
        try {
            cp.execSync(`wat2wasm "${tempWatPath}" --debug-names --enable-function-references -o "${path}"`);
            console.log(`Successfully compiled to ${path}`);
            // Optionally remove temp wat? Maybe keep it for debugging.
            // fs.unlinkSync(tempWatPath);
        } catch (e) {
            console.error("Compilation failed:", e.message);
            throw e;
        }
    }
}
