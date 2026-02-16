
import fs from 'fs';
import path from 'path';

// Load Browser Schema
const schemaPath = './browser_env.json';
const proxies = new Map();

export const kSchemaNode = Symbol("toSchemaNode");
export const kSchemaPath = Symbol("toSchemaPath");
export const kSchemaType = Symbol("toSchemaType");
export const kSchemaName = Symbol("toSchemaName");

export const getPath = (proxy) => Reflect.get(proxy, kSchemaPath);
export const getType = (proxy) => Reflect.get(proxy, kSchemaType);
export const getNode = (proxy) => Reflect.get(proxy, kSchemaNode);
export const getName = (proxy) => Reflect.get(proxy, kSchemaName);

const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));

function create(path, subkeys = true) {
    if (subkeys && proxies.has(path)) {
        return proxies.get(path);
    }

    const schemaPath = path;
    const schemaNode = schema[schemaPath];

    if (!schemaNode) {
        //console.error(`No schema for path:`, schemaPath);
        return "";
    }

    const schemaType = schemaNode.type;
    const schemaName = schemaNode.name;

    let func = `return ${schemaNode.value}`;


    switch (schemaType)  {
        case "class"    : func = `return class ${schemaName} {}`; break; 
        case "function" : func = `return function ${schemaName} () {}`; break; 
        case "object"   : func = `return new class ${schemaName} {}()`; break; 
    }

    let target = Function(func)();

    if (subkeys && target === Object(target)) {
        if (schemaName) {
            Object.defineProperty(target, Symbol.toStringTag, {
                value: schemaName
            });
        }

        Object.defineProperty(target, kSchemaNode, {value: schemaNode});
        Object.defineProperty(target, kSchemaType, {value: schemaType});
        Object.defineProperty(target, kSchemaPath, {value: schemaPath});
        Object.defineProperty(target, kSchemaName, {value: schemaName});

        target = Object.create(target);
    }

    if (subkeys && schemaNode.keys.length) {

        schemaNode.keys.forEach(key => {
            target[key] ??= create(schemaPath.concat(".", key), false);
        });

        proxies.set(schemaPath, target);
        proxies.set(target, schemaPath);
    }

    return target;
}

/**
 * Creates a recursive logging proxy that tracks the underlying value.
 * @param {any} target - The object/function to proxy.
 * @param {Proxy} [parent] - The parent proxy.
 * @param {string} [name] - The property name.
 * @param {object} [schemaNode] - The schema definition for this object (from browser_env.json).
 */
function createRecursiveProxy(path = 'self') {
    
    // 1. Determine the "Value"
    
    // 2. Logic to refine target based on schema
    // If we have a schema definition stating this is a function, we must use a function as target.
    // Otherwise it might be an object or primitive.

    const proxyTarget = create(path);
    
    const handler = {
        get(target, prop, receiver) {
            //console.log(`[Proxy] GET ${path}.${String(prop)}`);

            if (typeof prop === "symbol") {
                return Reflect.get(target, prop);
            }

            return createRecursiveProxy(path.concat(".", prop));
        },
        apply(target, thisArg, args) {
             const currentPath = getPath(proxy); 
             console.log(`[Proxy] CALL ${currentPath}(${args.map(a => String(a)).join(', ')})`);
             let result;
             try { result = Reflect.apply(target, thisArg, args); } catch (e) { result = undefined; }
             return createRecursiveProxy(result, proxy, `(return)`);
        },
        construct(target, args, newTarget) {
            const currentPath = getPath(proxy);
            console.log(`[Proxy] NEW ${currentPath}(${args.map(a => String(a)).join(', ')})`);
            let result;
            try { result = Reflect.construct(target, args, newTarget); } catch (e) { result = {}; }
            return createRecursiveProxy(result, proxy, `(instance)`);
        },
        set(target, prop, value, receiver) {
             const currentPath = getPath(receiver);
             console.log(`[Proxy] SET ${currentPath}.${String(prop)} =`, value);
             return Reflect.set(target, prop, value, receiver);
        },
        defineProperty(target, prop, descriptor) {
             const currentPath = getPath(proxy);
             console.log(`[Proxy] DEFINE ${currentPath}.${String(prop)}`, descriptor);
             return Reflect.defineProperty(target, prop, descriptor);
        }
    };

    return new Proxy(proxyTarget, handler);
}

export default createRecursiveProxy("self");
