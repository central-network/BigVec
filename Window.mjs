
import fs from 'fs';
import path from 'path';

export let self;

export const 
    kSchema = Symbol("kSchema"), 
    kParent = Symbol("kParent"), 
    kTypeOf = Symbol("kTypeOf"), 
    kPropName = Symbol("kPropName"), 
    kSelfPath = Symbol("kSelfPath");

const proxies = new WeakSet();

function isProxyPath (any) {
    return proxies.has(any);
}

class Externref { 
    static $tbl = new Array(null, "self.String.fromCodePoint", "self.Reflect.get");
    static type = "externref";
    
    static get size () { return this.$tbl.length; }

    get type () { return this.constructor.type; }
    get idx () { return Externref.$tbl.indexOf(this); }
    set value (v) {  }

    static add ($) { return this.$tbl[this.size] = $; }
    static has ($) { return this.$tbl.includes($); }
    static for (v) { return this[Object(v).constructor.name] ?? console.error("Unknown primitive:", v); }
    
    static String   = class Stringref   extends this { static from ( value = "" )       {}; static type = "string"; };
    static Number   = class Numberref   extends this { static from ( value = 0 )        {}; static type = "number"; };
    static Array    = class Arrayref    extends this { static from ( value = [] )       {}; static type = "array"; };
    static Symbol   = class Symbolref   extends this { static from ( value = Symbol() ) {}; static type = "symbol"; };
    static Bigint   = class Bigintref   extends this { static from ( value = 0n )       {}; static type = "bigint"; };
    static Boolean  = class Booleanref  extends this { static from ( value = false )    {}; static type = "boolean"; };
    static Object   = class Objectref   extends this { static from ( value = {})        {}; static type = "object"; };
    static Function = class Functionref extends this { static from ( value = () => {})  {}; static type = "function"; };

    constructor () { Externref.add(this) }

    static from (any) {
        if (any instanceof this) { return any };
        const ext = Reflect.construct(this.for(any), []);
        ext.value = any;
        return ext; 
    }

    get externref () { return this };
};



String.prototype.toCamelCase = function () {
    return this.at(0).toLowerCase().concat(
        this.substring(1)
    );
}

String.prototype.toBaseName = function () {
    let name = this.split(".").pop().split("[").at();
    if (name === "prototype") {
        name = this.toNodeName();
    }
    return name;
}

String.prototype.toParentPath = function () {
    return this.split(".").reverse().slice(1).reverse().join(".");
}

String.prototype.toClassName = function () {
    return this.split(".self.").pop().split(".").at();
};

String.prototype.toNodeName = function () {
    return this.split(".prototype").at().toBaseName().toCamelCase();
}

Object.defineProperties(Object.prototype, {
    typeof : {
        get : function () {
            switch (this.name) {
                case "Number": return "number";
                case "String": return "string";
                case "Symbol": return "symbol";
                case "object": return "object";
            }

            return "function";
        }
    },

    externref : { 
        get : function () { return Externref.from(this) } 
    }
});

/**
 * Creates a recursive logging proxy that tracks the underlying value.
 * @param {any} target - The object/function to proxy.
 * @param {Proxy} [parent] - The parent proxy.
 * @param {string} [name] - The property name.
 * @param {object} [schemaNode] - The schema definition for this object (from browser_env.json).
 */
function createRecursiveProxy(path = 'self', type = "function") {
    
    // 1. Determine the "Value"
    
    // 2. Logic to refine target based on schema
    // If we have a schema definition stating this is a function, we must use a function as target.
    // Otherwise it might be an object or primitive.

    let name, target;

    if (type !== "object") {
        name = path.toBaseName();
        target = Function(`return class ${name} extends this { path = '${path}'; type = '${type}';  }`).call(Externref);
    } else {
        name = path.toNodeName();
        target = Function(`return new class ${name} extends this { path = '${path}'; type = '${type}';  }`).call(Externref);
    }

    const _call     = ( ...args ) => { console.log(['.call', path], args);};
    const _apply    = ( thisArg, args ) => { console.log(['.apply', path], thisArg, args);};
    const _bind     = ( thisArg, ...args ) => { console.log(['.bind', path], thisArg, args);};
    const _path     = () => path;

    const prx = new Proxy(target, {

        apply: function (func, thisArg, argsList) {
            console.log(['APPLY', func.name], `${String(thisArg)}(`, ...argsList, `)`);
            return createRecursiveProxy(String(thisArg).concat(".", "apply"), "object");
        },

        set: function (externref, prop, value) {
             console.log(['SET', externref], `${path}[${JSON.stringify(String(prop))}] =`, value);
             return value;
        },

        defineProperty: function (target, prop, descriptor) {
            throw ['DEFINE', `${path}.${String(prop)}`, descriptor];
        },

        construct: function (obj, argsList) {
            console.log(['NEW', obj], `${path}`, argsList, obj.typeof);
            argsList.externref;
            obj.externref;
            return createRecursiveProxy(path.concat(".", "prototype"), obj.typeof);
        },

        get : function (obj, prop, prx) {
            console.log(['GET', prop], `${path}.${String(prop)}`);

            if (typeof prop === "symbol") {
                switch (prop) {
                    case Symbol.toString: 
                    case Symbol.toPrimitive: return _path;
                }
            }

            if (typeof prop === "string") {
                switch (prop) {
                    case "call"     : return _call;
                    case "apply"    : return _apply;
                    case "bind"     : return _bind;
                    case "toString" : return _path;
                }
            }

            return createRecursiveProxy(path.concat(".", prop));
        }
    });

    proxies.add(prx);

    return prx;
}

export default self = createRecursiveProxy("self");
