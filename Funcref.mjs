
/**
 * Funcref.mjs
 * 
 * Represents a reference to a function in the WASM 'funcref' table ($fun).
 * Unlike Externref (which manages dynamic handles), Funcref handles point to 
 * static, pre-compiled WASM functions defined in the kernel.
 * 
 * These indices correspond to the 'elem' segment in 'chain.mjs'.
 */


export class Funcref {
    static type = "funcref";

    module = new Array();

    constructor () {
        
    }

    toString () { 
        return `(module\n  ${1}\n)` 
    }
}
