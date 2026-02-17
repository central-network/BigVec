
import ChainBuilder from "./chain.mjs";
import { Externref, FunctionRef, ObjectRef, PrimitiveRef } from "./Externref.mjs";

/**
 * Compiler.mjs
 * 
 * The bridge between the high-level WCL syntax (Proxies) and the low-level ChainBuilder.
 * It manages the current compilation context, scope, and operation emission.
 */

export class Compiler {
    constructor() {
        this.builder = new ChainBuilder();
        this.currentBlock = null; // Track current block/scope if needed
        
        // Context tracking for "this" in calls?
        // Symbol map is handled by builder for now, but compiler might need its own.
    }

    /**
     * Emits an allocation operation for a standard constructor.
     * e.g. new Array() -> wasm_array_no_args
     */
    emitAlloc(className, args = []) {
        let op;
        switch (className) {
            case "Array":
                if (args.length === 0) {
                    op = this.builder.wasm_array();
                } else {
                    // Logic for new Array(len) or new Array(items...)
                    // For now default to empty
                    op = this.builder.wasm_array();
                }
                break;
            case "Object":
                // We don't have a specific alloc_struct op yet, maybe use array or Dictionary?
                // Let's assume generic array for now or special struct if available.
                // Reusing wams_array as placeholder for "Struct" logic
                op = this.builder.wasm_array(); 
                break;
            case "ArrayBuffer":
                // args[0] is length. 
                // We need an op that calls $alloc (func 0) perhaps? 
                // Or a specific import. For now, let's assume standard library handle.
                // Implementation pending specific opcode.
                console.warn("ArrayBuffer alloc not fully implemented, using empty array override.");
                op = this.builder.wasm_array();
                break;
             case "String":
                // args[0] is string value.
                if (args.length > 0 && typeof args[0] === 'string') {
                    // Constant string creation
                     return this.emitConstString(args[0]);
                }
                op = this.builder.create_string("");
                break;
            default:
                console.warn(`Unknown class alloc: ${className}`);
                op = this.builder.wasm_array();
        }
        
        // Track this op -> result is an Externref
        return op;
    }

    emitConstString(str) {
        return this.builder.create_string(str);
    }
    
    emitConstNumber(num) {
         // Create a number? value creation helper...
         // ChainBuilder doesn't have explicit "create constant number as externref".
         // Usually we use make_args to pass it to a function.
         // If we need it as a standalone Ref, we might need a "Identity" function or something.
         // For now, let's return the raw number, and let 'make_args' handle it when used.
         return num;
    }

    /**
     * Emits a property set operation.
     * target.prop = value
     */
    emitSet(targetOp, prop, valueOp) {
        // targetOp is the Externref (Operation) of the object.
        // prop is string key.
        // valueOp is the value.
        
        // We need to resolve 'prop' to a key op (string).
        const keyOp = this.builder.create_string(String(prop));
        
        // Now emit Reflect.set(target, key, value)
        // chain.wasm_set_ext_i32_i32 is actually set_ext_ext_ext wrapper we made?
        // flexible set.
        
        // In chain.mjs, we have 'wasm_set_eie' (externref, int, externref) etc.
        // We need 'externref, externref, externref' (Reflect.set basic).
        
        // Assuming we have a generic 'Reflect.set' import or wrapper.
        // Let's use the builder's helper if available, or raw apply.
        
        // Current builder has specific typed setters. 
        // Let's use 'wasm_set_ext_i32_i32' which was for Arrays/Structs with index?
        // For string keys, we need Reflect.set.
        
        // Fallback: Resolve Reflect.set and call it.
        const reflectSet = this.builder.resolve_path("self.Reflect.set");
        const args = this.builder.make_args([targetOp, prop, valueOp]); // make_args handles string prop creation
        this.builder.apply(reflectSet, null, args);
    }

    /**
     * Emits a function call.
     * method(...args)
     */
    emitCall(methodOp, thisArgOp, args = []) {
        // methodOp is the function to call.
        // thisArgOp is the context.
        // args is array of values.
        
        // Reflect.apply(target, thisArgument, argumentsList)
        const reflectApply = this.builder.resolve_path("self.Reflect.apply");
        const argArray = this.builder.make_args(args); // runtime array of args
        
        return this.builder.apply(reflectApply, null, this.builder.make_args([methodOp, thisArgOp, argArray]));
    }
    
    /**
     * Resolves a global path to an Op.
     */
    resolveGlobal(path) {
        return this.builder.resolve_path(path);
    }

    /**
     * Emits a property get operation on an object.
     * target.prop -> op
     */
    emitGet(targetOp, prop) {
        // Reflect.get(target, prop)
        const reflectGet = this.builder.resolve_path("self.Reflect.get");
        const propOp = this.builder.create_string(String(prop));
        
        // Reflect.get takes (target, propertyKey, [receiver])
        // We omit receiver for now (defaults to target).
        const args = this.builder.make_args([targetOp, propOp]);
        
        return this.builder.apply(reflectGet, null, args);
    }

    compile() {
        return this.builder.getHex(); // or .resolve() -> buffer
    }
}

// Singleton instance for the active session
export const compiler = new Compiler();
