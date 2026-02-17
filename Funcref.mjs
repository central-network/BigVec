
/**
 * Funcref.mjs
 * 
 * Represents a reference to a function in the WASM 'funcref' table ($fun).
 * Unlike Externref (which manages dynamic handles), Funcref handles point to 
 * static, pre-compiled WASM functions defined in the kernel.
 * 
 * These indices correspond to the 'elem' segment in 'chain.mjs'.
 */


const createPathProxy = (path = "wasm") => {
    const isParam = function () {
        return Array.from(arguments).filter(
            c => c === 0 || !!c
        );
    }

    const beautify = (code = "") => {
        let openers = 0;
        let closers = 0;
        code = code
            .replaceAll("wasm.", "")
            .replaceAll("(", "\n  (")
            .replaceAll(/\n\s+\n/g, " \n")
            .trim()
            .split("\n")
            .map((line, i) => {
                openers += line.split("(").length;
                closers += line.split(")").length;
                
                const count = (openers - closers)*2;
                return String("").padStart(count, " ").concat(line.trim());
            })
            .join("\n")
            .replaceAll("(param", "\n    (param")
            .replaceAll("(result", "\n    (result")
            .replaceAll(/\n\s+\n/g, "\n  ")
            .replaceAll("(func", "\n  (func")
            .replaceAll("(import", "\n  (import")
        ;
        
        return code;
    };

    const parse_meta = (argv = []) => {
        let arg0 = argv.splice(0,1).pop();
        if (!arg0) return [];

        if (arg0?.constructor !== Object) {
            argv.unshift(arg0);
        }
    
        const options = [];
    
        if (typeof arg0.name === "string") options.push(`${arg0.name}`);
        if (typeof arg0.type === "string") options.push(`${arg0.type}`);
        if (typeof arg0.offset === "string") options.push(`offset=${arg0.offset}`);
        if (typeof arg0.path === "string") options.push(`"${`self.${arg0.path}`.split(".").slice(-2).join('" "')}"`);
    
        return options.filter(isParam).flat();
    };

    const proxy = new Proxy(Function, {
        apply (target, thisArg, argv) {
            const meta = parse_meta(argv);
            const code = [path, ...meta, ...argv]
                .filter(isParam).flat().join(" ").trim();

            return beautify(`(${code})`);
        },

        get (target, prop) {
            if (prop === Symbol.toPrimitive) return () => path;
            return createPathProxy(path.concat(".", prop));
        }
    });

    return proxy;
}

const { 
    func, type, param, result,
    i32, f32, i64, f64, v128, 
    externref, funcref,
    local, global,
    ref, data, elem,
    table, memory, 
    import: imprt,
    module: mdule 
} = createPathProxy("wasm");

export class Funcref {
    static type = "funcref";

    module = new Array();

    constructor () {
        this.module.push(
            imprt({path: "self.Array"},
                func({ name: "$new_array" },
                    param(), result(externref)
                )
            ),
            imprt({path: "self.Reflect.set"},
                func({ name: "$set_number" },
                    param(externref, i32, i32), result()
                )
            ),
            imprt({path: "self.Reflect.set"},
                func({ name: "$set_externref" },
                    param(externref, i32, externref), result()
                )
            ),
            imprt({path: "self.Reflect.set"},
                func({ name: "$set_funcref" },
                    param(externref, i32, funcref), result()
                )
            ),
            imprt({path: "self.Reflect.apply"},
                func({ name: "$ext_apply" },
                    param(externref, externref, externref), result()
                )
            ),
            imprt({path: "self.console.log"},
                func({ name: "$logi" },
                    param(i32), result()
                )
            ),
            func({name: "$ext_grow"},
                param({name: "$ptr"}, i32),
                i32.store({offset: 12},
                    local.get({name: "$ptr"}),
                    table.grow({name: "$ext"},
                        ref.null({type: "extern"}),
                        i32.load({offset: 12},
                            local.get(0)
                        )
                    )
                )
            )
        );
    }

    toString () { return mdule(this.module.join("\n")) }
}
