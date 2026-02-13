
import fs from "fs";
import cp from "child_process";

const WASM_TEMPLATE = `(module
  (import "self" "self"             (global $self externref))
  (import "String" "fromCodePoint"  (global $self_String_fromCodePoint externref))
  (import "Reflect" "get"           (global $self_Reflect_get externref))

  (import "self" "Array"            (func $self_array (param) (result externref)))
  (import "Reflect" "set"           (func $self_set_eii (param externref i32 i32) (result)))
  (import "Reflect" "set"           (func $self_set_eie (param externref i32 externref) (result)))
  (import "Reflect" "set"           (func $self_set_eif (param externref i32 funcref) (result)))
  (import "Reflect" "apply"         (func $self_apply (param externref externref externref) (result externref)))
  
  (import "console" "log"           (func $log_eii (param externref i32 i32)))

  (;CHAIN_DATA;)

  (table $externref 4 65536 externref)
  (elem (table $externref) (i32.const 1) externref (global.get 0) (global.get 1) (global.get 2))

  (table $funcref 8 funcref)
  (elem (table $funcref) (i32.const 1)
    $wasm_array
    $wasm_set_eii
    $wasm_set_eie
    $wasm_set_eif
    $wasm_apply
    $copy
    $copyInto
  )

  (global $ptr (mut i32) (i32.const 0))

  (func $wasm_array
    (i32.store offset=12 (global.get $ptr) 
        (table.grow $externref (call $self_array) (i32.const 1))
    )
  )
  
  (func $wasm_set_eii
    (call $self_set_eii
        (table.get $externref (i32.load offset=12 (global.get $ptr)))
        (i32.load offset=16 (global.get $ptr))
        (i32.load offset=20 (global.get $ptr))
    )
  )

  (func $wasm_set_eie
    (call $self_set_eie
        (table.get $externref (i32.load offset=12 (global.get $ptr)))
        (i32.load offset=16 (global.get $ptr))                       
        (table.get $externref (i32.load offset=20 (global.get $ptr))) 
    )
  )
  
  (func $wasm_set_eif
    (call $self_set_eif
        (table.get $externref (i32.load offset=12 (global.get $ptr)))
        (i32.load offset=16 (global.get $ptr))
        (table.get $funcref (i32.load offset=20 (global.get $ptr)))
    )
  )

  (func $wasm_apply
    (i32.store offset=24 (global.get $ptr) 
        (table.grow $externref 
            (call $self_apply
                (table.get $externref (i32.load offset=12 (global.get $ptr))) 
                (table.get $externref (i32.load offset=16 (global.get $ptr))) 
                (table.get $externref (i32.load offset=20 (global.get $ptr))) 
            )
            (i32.const 1)
        )
    )
  )

  (func $copy
    (memory.copy 
        (i32.load offset=16 (global.get $ptr)) ;; dst
        (i32.load offset=12 (global.get $ptr)) ;; src
        (i32.load offset=20 (global.get $ptr)) ;; len
    )
  )

  (func $copyInto
    (local $target externref)
    (local $offset  i32)
    (local $length  i32)
    (local $begin   i32)
    (local $index   i32)

    (local.set $target (table.get $externref (i32.load offset=12 (global.get $ptr))))
    (local.set $offset (i32.load offset=16 (global.get $ptr)))
    (local.set $length (i32.load offset=20 (global.get $ptr)))
    (local.set $begin  (i32.load offset=24 (global.get $ptr)))
    
    (if (i32.ge_u (local.get $length) (i32.const 1))
        (then (local.set $index (local.get $length)))
        (else (return))
    )

    (loop $length--
        (local.set $index (i32.sub (local.get $index) (i32.const 1)))

        (call $self_set_eii 
            (local.get $target)
            (i32.add (local.get $begin) (local.get $index))
            (i32.load8_u (i32.add (local.get $offset) (local.get $index)))
        )

        (br_if $length-- (local.get $index))
    )
  )

  (func $start 
    (local $size i32)
    (local $func_idx i32)

    (loop $chain
      (local.tee $func_idx (i32.load offset=8 (global.get $ptr)))
      (if (then (call_indirect $funcref (local.get $func_idx))))

      (local.tee $size (i32.load offset=4 (global.get $ptr)))
      (global.set $ptr (i32.add (global.get $ptr)))

      (br_if $chain (local.get $size))
    )
  )
  
  (start $start) 
)`;

// Helper class for a single chain operation
class Operation {
    constructor(id, type, size, funcIndex, writePayloadFn) {
        this.id = id;
        this.type = type;
        this.size = size; // Payload size
        this.funcIndex = funcIndex;
        this.writePayloadFn = writePayloadFn; // Function to write payload to view
        this.offset = 0; // Will be calculated
        this.tableIdx = -1; // Predicted externref table index (if applicable)
    }
}

const [ offset, lines, elem_$funcref = Object.fromEntries(lines.match(/\$(.[^\s]*)/g).map((fn, i) => [fn.substring(1), i+ +offset]))
] = Array.from(WASM_TEMPLATE.match(/\(elem\s+\(table\s+\$funcref\)\s+\(i32\.const\s+(\d+)\)\s*(?:(\$.[^\)]*)\s)*\)/m)).slice(1);

export default class ChainBuilder {
    constructor() {
        this.ops = [];
        this.opCounter = 0;
        
        // Track the next available externref table index in WASM
        this.tbl_idx = 4;
        
        // Symbol Table for tracking externref indices
        this.symbolMap = new Map([
            ["$null", 0],
            ["$self", 1],
            ["$self.String.fromCodePoint", 2],
            ["$self.Reflect.get", 3]
        ]);
        
        this.functions = {
            ...elem_$funcref, end: 0
            /*
            wasm_array: 1,
            wasm_set_eii: 2,
            wasm_set_eie: 3,
            wasm_set_eif: 4,
            wasm_apply: 5,
            copy: 6,
            copyInto: 7,
            */
        };

        this.init_standard_library();
    }

    addOp(type, size, funcIndex, writePayloadFn) {
        const id = `op_${this.opCounter++}`;
        const op = new Operation(id, type, size, funcIndex, writePayloadFn);
        this.ops.push(op);
        
        // Predict table index for operations that grow the table
        if (type === 'array' || type === 'apply' || type === 'buffer') {
            op.tableIdx = this.tbl_idx++;
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
    }

    wasm_array() {
        return this.addOp('array', 4, this.functions.wasm_array, (view, offset) => {
            view.setInt32(offset, 0, true); 
        });
    }
    
    wasm_apply(func, thisArg, argsList) {
        const op = this.addOp('apply', 16, this.functions.wasm_apply, (view, offset) => {
            view.setInt32(offset, func, true);
            view.setInt32(offset+4, thisArg, true);
            view.setInt32(offset+8, argsList, true);
            view.setInt32(offset+12, 0, true); // Result
        });
        return op;
    }

    apply (opFunc, thisArg, argsList) {
        if (false === argsList instanceof Operation) {
            argsList = this.make_args(argsList);
        }

        if (false === opFunc instanceof Operation) {
            opFunc = this.resolve_path(`${opFunc}`);
        }

        return this.apply_func(opFunc, thisArg, argsList);
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

    get $self () { return this.path_resolver_proxy(); }

    path_resolver_proxy (path = "self") {
        return new Proxy(new Function, {
            apply : (obj, thisArg, argsList) => {
                return this.apply(path, thisArg, argsList)
            },

            construct: (obj, argsList) => {
                return this.construct(path, argsList);
            },

            get : (obj, key) => {
                if (key === Symbol.toPrimitive) {
                    return () => path;
                }

                if (key === "call") {
                    return (thisArg, ...argsList) => {
                        return this.apply(
                            path, thisArg, argsList
                        )
                    };
                }

                if (key === "apply") {
                    return (thisArg, argsList) => {
                        return this.apply(path, thisArg, argsList)
                    };
                }

                return this.path_resolver_proxy(
                    path.concat(".", key)
                );
            }
        });
    }
    
    wasm_set_eii(objIndexOrAddress, key, value) {
        const op = this.addOp('set_i32', 12, this.functions.wasm_set_eii, (view, offset) => {
             view.setInt32(offset, objIndexOrAddress, true); 
             view.setInt32(offset + 4, key, true);     
             view.setInt32(offset + 8, value, true);       
        });
        return op;
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
        
        const op = this.addOp('alloc', byteLength + opHeadersLength, this.functions.copyInto, (view, offset) => {            
            view.setInt32(offset, $bufferView.tableIdx, true);
            view.setInt32(offset + 4, offset + opHeadersLength, true);
            view.setInt32(offset + 8, byteLength, true);
            view.setInt32(offset + 12, 0, true);
        });

        $buffer.data = data;
        op.buffer = $buffer;

        return $buffer;
    }

    wasm_set_eie(obj, key, val) {
        const op = this.addOp('set_ext', 12, this.functions.wasm_set_eie, (view, offset) => {
            view.setInt32(offset, obj, true);
            view.setInt32(offset+4, key, true);
            view.setInt32(offset+8, val, true);
        });
        return op;
    }
    
    copy(srcOp, dstOp, dstOffset, length) {
        const idx = this.ops.indexOf(dstOp);
        if (idx === -1) throw new Error("Target operation not found in chain");

        const op = new Operation(`op_${this.opCounter++}`, 'copy', 12, this.functions.copy, (view, offset, resolveFn) => {
            const srcInnerOffset = (srcOp.type === 'apply') ? 24 : 
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
            const opVal = this.create_value(code);
            const opIdx = this.create_value(index);
            const opSet = this.wasm_set_eii(0, 0, 0);
            
            this.copy(opArgs, opSet, 0, 4);   // Array
            this.copy(opIdx, opSet, 4, 4);    // Key
            this.copy(opVal, opSet, 8, 4);    // Value
        });
        
        const opApply = this.wasm_apply(0, 0, 0);
        const opFunc = this.get_externref("$self.String.fromCodePoint");
        
        this.copy(opFunc, opApply, 0, 4);
        this.copy(opArgs, opApply, 8, 4); // Args list
        
        this.symbolMap.set(str, opApply.tableIdx);
        
        return opApply;
    }

    make_args(items) {
        const opArr = this.wasm_array();
        items.forEach((itemOp, index) => {
            let setter;

            switch (typeof itemOp) {
                case "number":
                    setter = "wasm_set_eii";
                    itemOp = this.create_value(itemOp);
                break;

                case "string":
                    setter = "wasm_set_eie";
                    itemOp = this.create_string(itemOp);
                break;

                default:
                    if (Array.isArray(itemOp)) {
                        itemOp = this.make_args(itemOp);
                    }

                    setter = "wasm_set_eie";
                    itemOp = itemOp;
                break;
            }

            const opSet = this[setter](0,0,0);
            const opIdx = this.create_value(index);

            this.copy(opArr, opSet, 0, 4);
            this.copy(opIdx, opSet, 4, 4);
            this.copy(itemOp, opSet, 8, 4);
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
            "$self.Promise.prototype.catch"
        ];
        
        for(const path of standardLib) {
            this.resolve_path(path);
        }
    }


    end() {
        this.endOp = this.addOp('end', 0, this.functions.end, () => {});
    }

    resolve() {
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
            view.setInt32(opStart, prevPtr, true); 
            view.setInt32(opStart + 4, 12 + op.size, true); 
            view.setInt32(opStart + 8, op.funcIndex, true); 
            op.writePayloadFn(view, opStart + 12, (targetOp) => getAddr(targetOp));
            
            if ("buffer" in op && "data" in op.buffer) { 
                let data = Buffer.from(op.buffer.data),
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
            cp.execSync(`wat2wasm "${tempWatPath}" --enable-function-references -o "${path}"`);
            console.log(`Successfully compiled to ${path}`);
            // Optionally remove temp wat? Maybe keep it for debugging.
            // fs.unlinkSync(tempWatPath);
        } catch (e) {
            console.error("Compilation failed:", e.message);
            throw e;
        }
    }
}
