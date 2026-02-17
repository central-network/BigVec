
/**
 * Externref.mjs
 * 
 * Represents a handle to a value in the WASM 'externref' table.
 * This is the base unit of the WASM Chain Language.
 * 
 * At compile-time, it represents a "Future Value" or a "Constant".
 * At run-time, it allows introspection of what that value *will be*.
 */

export class Externref {
    static type = "externref";
    
    constructor(val = null) {
        // If constructed with a value, it might be a constant or an initial value.
        // For now, we just store it for debug/compile-time analysis.
        this.initialValue = val;
        
        // Symbols to track meta-data without polluting the object namespace
        // used by the Proxy/Builder later.
        this.id = Symbol("ExternrefID"); 
    }

    // Type checking helpers
    get isPrimitive() { return false; }
    get isRef() { return true; }

    static from(value) {
        if (value instanceof Externref) return value;
        
        // Constant / Primitive lifting
        if (value === null || value === undefined) return new Externref(null); // Nullref ideally
        
        const type = typeof value;
        
        switch (type) {
            case 'number': return new NumberRef(value);
            case 'string': return new StringRef(value);
            case 'boolean': return new BooleanRef(value);
            case 'function': return new FunctionRef(value);
            case 'object': 
                if (Array.isArray(value)) return new ArrayRef(value);
                return new ObjectRef(value);
            case 'symbol': return new SymbolRef(value);
            case 'bigint': return new BigIntRef(value);
            default:
                console.warn(`Unknown type ${type}, defaulting to generic Externref.`);
                return new Externref(value);
        }
    }
}

// --- Subclasses for Specific WASM/JS Types ---

export class PrimitiveRef extends Externref {
    get isPrimitive() { return true; }
}

export class NumberRef extends PrimitiveRef {
    static type = "number";
    constructor(val) { super(val); }
}

export class StringRef extends PrimitiveRef {
    static type = "string";
    constructor(val) { super(val); }
}

export class BooleanRef extends PrimitiveRef {
    static type = "boolean";
    constructor(val) { super(val); }
}

export class BigIntRef extends PrimitiveRef {
    static type = "bigint";
    constructor(val) { super(val); }
}

export class SymbolRef extends PrimitiveRef {
    static type = "symbol";
    constructor(val) { super(val); }
}

export class ObjectRef extends Externref {
    static type = "object";
    constructor(val) { super(val); }
}

export class ArrayRef extends ObjectRef {
    static type = "array";
    constructor(val) { super(val); }
}

export class FunctionRef extends ObjectRef {
    static type = "function";
    constructor(val) { super(val); }
}
