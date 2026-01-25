import helpers from "../helpers.js"

export const STRING_BLOCK_NAME = "string";

export default function (wat) {

    while (helpers.hasBlock(wat, STRING_BLOCK_NAME)) {

        let oldBlock = helpers.lastBlockOf(wat, STRING_BLOCK_NAME);
        const string = helpers.findQuotedText(oldBlock);
        const ccodes = helpers.encodeString(string);

        if (ccodes.length === 0) {
            wat = oldBlock.replacedRaw(`
                (reflect $apply<ext.ext.ext>ext
                    (global.get $self.String.fromCharCode) 
                    (self)
                    (self)
                )
            `);
        }
        else if (ccodes.length === 1) {
            wat = oldBlock.replacedRaw(`
                (reflect $apply<ext.ext.ext>ext
                    (global.get $self.String.fromCharCode)
                    (self)
                    (array $of<i32>ext (i32.const ${string.charCodeAt(0)})) ;; "${string}"
                )
            `);
        }
        else {
            wat = oldBlock.replacedRaw(`
                (block (; "${helpers.abstract(string)}" ;)
                    (result externref)
                    (global.set $wat4wasm (call $self.Array<>ext))
                    
                    ${ccodes
                    .map((c, i) => `(global.get $wat4wasm) (i32.const ${i}) (i32.const ${c})`)
                    .map((args) => `(call $self.Reflect.set<ext.i32.i32> ${args})`)
                    .join("\n")}
    
                    (call $self.Reflect.apply<ext.ext.ext>ext
                        (global.get $self.String.fromCharCode) 
                        (ref.null extern) 
                        (global.get $wat4wasm)
                    ) 
                    ;; stacked
    
                    (global.set $wat4wasm (null)) 
                    ;; cleared
                )
            `);
        }
    }

    return wat;
}