
import { Externref, ObjectRef } from "./Externref.mjs";
import { compiler } from "./Compiler.mjs";

/**
 * Global.mjs
 * 
 * Defines the GlobalProxy which acts as the entry point (Root) of the WCL.
 * It uses a Lazy Resolution strategy:
 * - Accessing properties builds up a path string (e.g. self.console.log)
 * - Operations (Call, Construct, Set, or direct .externref access) force resolution via Compiler.
 */

// Private symbols 
const kOp = Symbol("kOp");
const kName = Symbol("kName");

export const kDebug = Symbol.for('nodejs.util.inspect.custom');

/**
 * Creates a proxy wrapper around an Operation (Externref).
 * This ensures every access (get) results in a new Operation on the chain.
 * 
 * @param {Operation} op - The current operation/externref.
 * @param {string} [name] - Optional name hint for optimization (e.g. "Array").
 * @param {Operation} [parent] - The parent object (valuable for 'this' context in calls).
 */
function createProxy(op, name = "Anonymous", parent = null) {
    
    // Target is a dummy function to allow apply/construct traps.
    // We name it for better debugging.
    const proxyTarget = {[name]: function(){}}[name];
    
    return new Proxy(proxyTarget, {
        get(target, prop, receiver) {

            // 3. Custom Inspection (Node.js & QuickJS?)
            if (prop === kDebug) {
                return (depth, options, inspect) => {
                    return { type: name, op: op.id, parent: parent ? parent.id : "root" };
                };
            }

            if (typeof prop === "symbol") return Reflect.get(target, prop);

            // 1. Introspection
            if (prop === "externref" || prop === kOp) return op;
            if (prop === "parent") return parent;
            
            // 2. Special properties
            if (prop === "then") return undefined; 
            
            
            // 4. ToPrimitive / ToString
            if (prop === Symbol.toPrimitive || prop === "toString") {
                return () => `[WCL.Ref: ${name}]`;
            }

            // 4. Property Access -> Emit Get Operation immediately
            // self.console -> op(Get self, "console")
            const propName = String(prop);
            const propOp = compiler.emitGet(op, propName);
            
            // Return new Proxy wrapping the result op
            // The current 'op' becomes the 'parent' of the new proxy.
            return createProxy(propOp, propName, op);
        },

        apply(target, thisArg, args) {
             // Method Call -> obj.method(...)
             // 'op' is the function (method).
             // 'parent' is likely the object it was accessed from (obj).
             // 'thisArg' logic in Proxy trap:
             //   obj.method() -> thisArg is obj (our parent proxy usually).
             //   method.call(ctx) -> thisArg is ctx.
             
             let contextOp = null;
             
             // If thisArg is provided and has an externref, use it.
             if (thisArg && thisArg.externref) {
                 contextOp = thisArg.externref;
             } 
             // Fallback: use the parent from which we got this method?
             // e.g. self.console.log() -> parent is self.console
             else if (parent) {
                 contextOp = parent;
             }
             // Fallback: Global/Undefined?
             else {
                 contextOp = compiler.resolveGlobal("self"); 
             }
             
             const resolvedArgs = args.map(arg => {
                 if (arg && arg.externref) return arg.externref;
                 return arg; 
             });
             
             const resultOp = compiler.emitCall(op, contextOp, resolvedArgs);
             return createProxy(resultOp, `${name}()_Result`, null);
        },

        construct(target, args) {
             // Constructor -> new Array(...)
             // 'op' is the class constructor.
             
             const resolvedArgs = args.map(arg => {
                 if (arg && arg.externref) return arg.externref;
                 return arg;
             });
             
             // Optimization: Check name hint for known constructors that have optimized instructions
             if (name === "Array" || name === "Object" || name === "ArrayBuffer" || name === "String") {
                 const resultOp = compiler.emitAlloc(name, resolvedArgs);
                 return createProxy(resultOp, `${name}_Instance`, null);
             }

             // General Case: We need a generic 'Construct' op.
             // Current ChainBuilder might not have it exposed directly yet?
             // We can simulate via Reflect.construct if imported?
             // For now, warn and return generic alloc or fail.
             console.warn(`[WCL] Generic 'new ${name}()' not fully optimized. Using empty array placeholder.`);
             const resultOp = compiler.emitAlloc("Object", resolvedArgs); 
             return createProxy(resultOp, `${name}_Instance`, null);
        },

        set(target, prop, value) {
            // obj.prop = val
            // 'op' is the object.
            let valueOp = value;
            if (value && value.externref) valueOp = value.externref;
            
            compiler.emitSet(op, String(prop), valueOp);
            return true;
        }
    });
}

// 1. Resolve Root (self)
// We assume 'self' is always available as a starting point.
const rootOp = compiler.resolveGlobal("self");
export const self = createProxy(rootOp, "self");

export { Externref };
