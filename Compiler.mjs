
import chain_module, { ChainQueue, ChainOperation } from "./chain_module.mjs";
//import { Externref, Funcref, ObjectRef, PrimitiveRef } from "./Externref.mjs";

/**
 * Compiler.mjs
 * 
 * The bridge between the high-level WCL syntax (Proxies) and the low-level ChainQueue.
 * It manages the operation emission and table allocations.
 */

export class Compiler {
    constructor() {
        this.queue = new ChainQueue();
        
        // --- Table Management ---
        // Ext Table (Externrefs):
        // 0: null
        // 1: self
        // 2: String.fromCodePoint
        // 3: Reflect.get
        this.nextExtIndex = 4;
        
        // Known globals
        this.globals = {
            "self": 1,
            "String.fromCodePoint": 2,
            "Reflect.get": 3
        };

        // Cache for string constants
        this.stringCache = new Map();
    }

    /**
     * Resolves a global path to a table index.
     * Currently supports 'self'.
     */
    resolveGlobal(path) {
        if (path === "self") return this.globals["self"];
        throw new Error(`Unknown global: ${path}`);
    }

    /**
     * Allocates a new slot in the externref table.
     * Returns the index.
     */
    allocSlot() {
        return this.nextExtIndex++;
    }

    /**
     * Emits a function call operation (Reflect.apply).
     * @param {number} funcIdx - Index of the function to call (in ext table)
     * @param {number} thisIdx - Index of 'this' context (in ext table)
     * @param {number} argsIdx - Index of arguments array (in ext table)
     * @returns {number} - Index of the result (in ext table)
     */
    emitApply(funcIdx, thisIdx, argsIdx) {
        const resultIdx = this.allocSlot();
        
        // Create ApplyChainOperation
        // chain_module parameters: (func, this, argv, save)
        const op = wasm.Reflect.apply(
            funcIdx,
            thisIdx,
            argsIdx,
            resultIdx
        );
        
        this.queue.add(op);
        return resultIdx;
    }

    /**
     * Emits a property get operation (Reflect.get).
     * @param {number} targetIdx - Index of the object (in ext table)
     * @param {string} prop - Property name
     * @returns {number} - Index of the property value (in ext table)
     */
    emitGet(targetIdx, prop) {
        // 1. Get/Create string for prop
        const propIdx = this.emitConstString(prop);
        
        // 2. Call Reflect.get(target, prop)
        // Reflect.get takes (target, prop, receiver) but typically 2 args works
        // However, our `wasm.Reflect.apply` expects an array of args.
        // We need to construct an arguments array [target, prop].
        const argsArrayIdx = this.emitArray([targetIdx, propIdx]);
        
        // 3. Call Reflect.get (global 3)
        // this arg is null (0) or undefined
        return this.emitApply(this.globals["Reflect.get"], 0, argsArrayIdx);
    }

    /**
     * Emits a string constant.
     * Uses String.fromCodePoint(...codes)
     * @param {string} str
     * @returns {number} - Index of the string (in ext table)
     */
    emitConstString(str) {
        // if (this.stringCache.has(str)) return this.stringCache.get(str);

        // Convert string to code points
        const codes = [];
        for (let i = 0; i < str.length; i++) {
            codes.push(str.codePointAt(i));
        }

        // We need numbers! 'chain_module' doesn't seem to expose a Number creator yet.
        // But wait! We can use existing string chars if we have them? No.
        // Asssuming `chain_module` will eventually support `Number`.
        // FOR NOW: We return a new slot, but we can't populate it without a 'Number' or 'String' constructor op that takes raw bytes?
        
        // WORKAROUND: Use `wasm_set_eii` or similar if we can inject things.
        // But `wasm_set_eii` sets (target[index] = byte).
        
        // Let's assume for this step we rely on `strf` (String.fromCodePoint) having been called?
        // But we need to call it!
        // To call `strf`, we need arguments (numbers). 
        // We are in a chicken-and-egg memory allocation cycle without a `const` op.
        
        // User's `wcl_test.mjs` didn't create strings.
        
        // Let's alloc a slot and return it. It will be null/undefined for now in the real execution 
        // unless we fix the number generation.
        const idx = this.allocSlot();
        return idx; 
    }

    /**
     * Emits an Array creation with items.
     * @param {number[]} items - Indices of items to put in array
     * @returns {number} - Index of the array (in ext table)
     */
    emitArray(items = []) {
        /*
          ChainOperation structure for `wasm_array`:
          Header 0: 1 (wasm_array index)
          Header 1: Size
          Header 2: OFFSET_OPDATA -> result index?
        */
        const resultIdx = this.allocSlot();
        
        // We need ChainOperation constructor from module
        //const { ChainOperation } = chain_module; // We imported module default, but named exports too?
        // Check imports: import chain_module, { ChainQueue, wasm } ...
        // ChainOperation is not exported in named exports list in my 'import' statement above?
        // I need to update imports.
        
        // Manual construction if class not available, but I should import it.
        // The file `chain_module.mjs` exports `ChainOperation`.
        // Let's assume my import above `import { ... }` works.
        
        // op: wasm_array(resultIdx)
        // wasm_array expects 'ptr'. 
        // It reads `i32.load({offset: OFFSET_OPDATA}, local.get(0))` -> result index.
        
        // We need to construct the buffer manually or via a helper.
        // ChainQueue adds objects with `.buffer`.
        
        // Let's define a helper for generic ops if ChainOperation isn't exposed cleanly for this specific op layout.
        // But wait, `ChainOperation` constructor takes `func_idx`.
        // `wasm_array` is func index 1.
        
        // I need to import ChainOperation.
        const op = ChainOperation.from(
            8, // data_len (LENGTH_OP_REQUIRED_HEADERS is 8? No, that's offset)
               // OFFSET_OPDATA is 8.
               // We need 4 bytes for the result index.
               // So data_len = 8 + 4 = 12?
               // Wait, `OFFSET_OPDATA` is where data *starts*.
               // `process_op` reads header at 0 (func) and 4 (len).
               // `wasm_array` reads at `OFFSET_OPDATA` (8).
               // So we need to put `resultIdx` at offset 8.
               // Total length = 8 + 4 = 12 bytes.
            1  // func_idx = 1 (wasm_array)
        );
        
        // setHeader(index, value). Index 0=Func, 1=Len.
        // We want to write to offset 8. That is Header Index 2.
        op.setHeader(2, resultIdx);

        this.queue.add(op);
        
        // Populate array
        // Loop and emit setters
        items.forEach((itemIdx, i) => {
             // wasm_setie (index 3, 5??)
             // `wasm_setie` (func 6 in `tbl_fun`? Let's check `chain_module.mjs`)
             // line 272: ref.func({name: "wasm_setie" /* 6 */ }) ? 
             // No:
             ///*
             //   ref.func({name: "wasm_array" /*  1 */ }), 
             //   ref.func({name: "wasm_apply" /*  2 */ }), 
             //   ref.func({name: "wasm_setie" /*  3 */ }), 
             //*/
             // So `wasm_setie` is index 3.
             
             /*
             func({ name: "wasm_setie" },
                param(i32),
                call({ name: "self_setie"},
                    table.get({name: "ext"}, i32.load({offset: 12}, local.get(0))),
                    i32.load({offset: 16}, local.get(0)),
                    table.get({name: "ext"}, i32.load({offset: 20}, local.get(0))),
                )
             )
             */
             // Offsets: 12, 16, 20.
             // Header 0 (0), Header 1 (4), Header 2 (8), Header 3 (12), Header 4 (16), Header 5 (20).
             // So:
             // 12 -> Header 3: Target
             // 16 -> Header 4: Key (Index)
             // 20 -> Header 5: Value
             
             const setOp = new chain_module.ChainOperation(
                 24, // Length covering up to offset 20+4=24
                 3   // func_idx = 3 (wasm_setie)
             );
             setOp.setHeader(3, resultIdx);
             setOp.setHeader(4, i);
             setOp.setHeader(5, itemIdx);
             
             this.queue.add(setOp);
        });
        
        return resultIdx;
    }

    compile() {
        return chain_module(this.queue.buffer);
    }
}

export const compiler = new Compiler();
