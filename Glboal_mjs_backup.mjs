
import { compiler } from "./Compiler.mjs";
import util from "util";

export const kDebug = Symbol("WCL.Debug");
export const kOp = Symbol("WCL.Op");

/**
 * Creates a Proxy for WCL operations.
 * @param {number} idx - The table index in the WASM instance.
 * @param {string} name - Debug name.
 * @param {object} parent - Parent proxy/node info.
 */
function createProxy(idx, name = "Anonymous", parent = null) {
    
    // Target is a dummy function to allow apply/construct traps.
    const proxyTarget = {[name]: function(){}}[name];
    
    return new Proxy(proxyTarget, {
        get(target, prop, receiver) {
            // 1. Introspection
            if (prop === "externref" || prop === kOp) return idx;
            if (prop === "parent") return parent;
            if (prop === "then") return undefined; // Promise safety

            // 2. Custom Inspection
            if (prop === Symbol.for('nodejs.util.inspect.custom') || prop === util.inspect.custom) {
                return (depth, options, inspect) => {
                    return `WCL.Ref { type: '${name}', idx: ${idx} }`;
                };
            }
            
             // 3. toString (for console.log/templates)
            if (prop === 'toString' || prop === Symbol.toStringTag) {
                return () => `[WCL.Ref ${name} #${idx}]`;
            }

            // 4. Property Access -> Emit Get Operation
            const propName = String(prop);
            const resultIdx = compiler.emitGet(idx, propName);
            
            return createProxy(resultIdx, propName, { idx, name });
        },

        apply(target, thisArg, args) {
             // 1. Resolve arguments
            // args can be proxies or primitives.
            // primitives need to be converted to Externrefs (not implemented fully yet).
            // For now assume proxies.
            
            // Collect indices
            const argIndices = args.map(arg => {
                if (arg && arg[kOp] !== undefined) return arg[kOp];
                // TODO: Handle primitives (compiler.emitConst...)
                return compiler.emitConstString(String(arg)); 
            });
            
            // 2. Resolve 'this'
            // If called as method (proxy.foo()), thisArg is the proxy.
            const thisIdx = (thisArg && thisArg[kOp] !== undefined) ? thisArg[kOp] : 0;
            
            // 3. Emit arrays for args
            const argsArrayIdx = compiler.emitArray(argIndices);
            
            // 4. Emit Call of Reflect.apply? 
            // Wait, we are calling a function (target).
            // target is essentially the function ref.
            // Reflect.apply(target, thisArgument, argumentsList)
            const resultIdx = compiler.emitApply(idx, thisIdx, argsArrayIdx);
            
            return createProxy(resultIdx, `Call(${name})`, { idx });
        },

        construct(target, args) {
            // Similar to apply but for 'new'
            // For WCL, 'new Array()' is special -> emitArray
            // But we might be constructing other things.
            // Since we don't have a generic 'Construct' op yet, we might fallback to apply 
            // or if it's 'Array', optimize.
            
            // For now, logging strict array
            // if (name === "Array") ...
            
             const argIndices = args.map(arg => {
                if (arg && arg[kOp] !== undefined) return arg[kOp];
                return compiler.emitConstString(String(arg)); 
            });
            const argsArrayIdx = compiler.emitArray(argIndices);
            
            // Using apply for now as placeholder for new Object() etc.
            const resultIdx = compiler.emitApply(idx, 0, argsArrayIdx);
            return createProxy(resultIdx, `New(${name})`, { idx });
        }
    });
}

// 1. Resolve Root (self)
// Compiler has 'self' at index 1 by default.
const rootIdx = compiler.resolveGlobal("self");
export const self = createProxy(rootIdx, "self");

// Default export for convenience
export default self;
