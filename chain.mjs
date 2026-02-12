
import fs from "fs";
import cp from "child_process";

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

class ChainBuilder {
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
            wasm_array: 1,
            wasm_set_eii: 2,
            wasm_set_eie: 3,
            wasm_set_eif: 4,
            wasm_apply: 5,
            copy: 6,
            end: 0
        };
    }

    addOp(type, size, funcIndex, writePayloadFn) {
        const id = `op_${this.opCounter++}`;
        const op = new Operation(id, type, size, funcIndex, writePayloadFn);
        this.ops.push(op);
        
        // Predict table index for operations that grow the table
        if (type === 'array' || type === 'apply') {
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
    
    wasm_set_eii(objIndexOrAddress, key, value) {
        const op = this.addOp('set_i32', 12, this.functions.wasm_set_eii, (view, offset) => {
             view.setInt32(offset, objIndexOrAddress, true); 
             view.setInt32(offset + 4, key, true);     
             view.setInt32(offset + 8, value, true);       
        });
        return op;
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
            const opSet = this.wasm_set_eie(0, 0, 0);
            const opIdx = this.create_value(index);
            
            this.copy(opArr, opSet, 0, 4);
            this.copy(opIdx, opSet, 4, 4);
            this.copy(itemOp, opSet, 8, 4);
        });
        return opArr;
    }

    apply_func(funcOp, thisOp, argsOp) {
        const opApply = this.wasm_apply(0, 0, 0);
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
        this.addOp('end', 0, this.functions.end, () => {});
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
         const getAddr = (op) => 0 + op.offset; // Adjusted to 0

        for (const op of this.ops) {
            const opStart = op.offset;
            view.setInt32(opStart, prevPtr, true); 
            view.setInt32(opStart + 4, 12 + op.size, true); 
            view.setInt32(opStart + 8, op.funcIndex, true); 
            op.writePayloadFn(view, opStart + 12, (targetOp) => getAddr(targetOp));
            prevPtr = getAddr(op);
        }
        return buffer;
    }

    getHex() {
        const buffer = this.resolve();
        return Array.from(buffer)
            .map(b => b.toString(16).padStart(2, '0'))
            .join('').replaceAll(/(..)/g, '\\$1');
    }
}

const chain = new ChainBuilder();

// 1. Initialize Standard Library
chain.init_standard_library();

// 2. Test Scenario: MessageEvent Prototype Access
const opDataGetter = chain.resolve_path("$self.MessageEvent.prototype.data[get]");
const opInstance = chain.resolve_path("$self.myTestEvent");

// C. Call getter on instance
const opArgsEmpty = chain.wasm_array();
const opResultData = chain.apply_func(opDataGetter, opInstance, opArgsEmpty);

// D. Log the result
const opLogFunc = chain.resolve_path("$self.console.log[value]");
const opConsole = chain.resolve_path("$self.console");

const opArgsLog = chain.make_args([opResultData]);

chain.apply_func(opLogFunc, opConsole, opArgsLog);

chain.end();

const hexIdx = chain.getHex();
const template = fs.readFileSync("src/h.wat", "utf8");
// Replaced offset 48 with 0
const wat = template
    .replace("(;CHAIN_DATA;)", `
    (memory ${Math.ceil(hexIdx.length/(3*65536))})
    (data (i32.const 0) "${hexIdx}")`);

fs.writeFileSync("/tmp/chain.wat", wat);
cp.execSync("wat2wasm /tmp/chain.wat --enable-function-references -o h.wasm");
console.log("Compiled h.wasm successfully!");

// --- Run the WASM ---
const wasmBuffer = fs.readFileSync("h.wasm");
const wasmModule = new WebAssembly.Module(wasmBuffer);

// Create a test event with data
const testEvent = new MessageEvent('test_event', { data: 'Prototype Power!' });
global.myTestEvent = testEvent;

const imports = {
    self: {
        Array: () => [], 
        self: global,
    },
    Reflect: {
        set: Reflect.set, // Function imports automatically adapt signature
        get: Reflect.get,
        apply: Reflect.apply,
        getOwnPropertyDescriptor: Reflect.getOwnPropertyDescriptor
    },
    String: {
        fromCodePoint: String.fromCodePoint
    },
    console: console
};

console.log("Instantiating WASM...");
new WebAssembly.Instance(wasmModule, imports);
console.log("WASM Executed Successfully!");
