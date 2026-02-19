import { execSync } from "child_process";
import { writeFileSync, unlinkSync } from "fs";

export const createProxy = (path) => new Proxy(Function, {
    apply (target, thisArg, argv) {
        let args = [];
        
        while (argv.length) {
            let prime = "", arg0 = argv.pop();
        
            if (arg0 !== Object(arg0)) {
                prime = String(arg0);
            }
            else if (arg0.constructor === Array) {
                prime = arg0.map(String).join(" ");
            }
            else if (arg0.constructor === Object) {
                prime = Object.keys(arg0).map((key, i) => {
                    switch (key) {
                        case "import": return `(import "${arg0[key].join('" "')}")`;
                        case "export": return `(export "${arg0[key]}")`;
                        case "offset": return `${key}=${arg0[key]}`;
                        case "offset_u32i": return `offset=${arg0[key]*4}`;
                        case "name":   return `$${arg0[key]}`;
                        case "type":   return `${arg0[key]}`;
                    }
                    throw [ "Unknown key definer", key, arg0[i] ]
                }).join(" ");
            }
            else if (arg0 instanceof Function || arg0 instanceof String) {
                prime = `${arg0}`;
            }
            else throw [ "Unknown nonprime", arg0 ]
        
            args.unshift(prime);
        }
        
        const wat = `\n(${path} ${args.join(" ").trim()})`;
        return Object.defineProperties(new String(wat), {
            compile : { 
                value : (file, dump_module = false, options = []) => {
                    options = [ ...options, "--debug-names", "--enable-threads", "--enable-function-references" ];
                    let wasm, temp = "/tmp/wat_proxy";

                    try {
                        writeFileSync(temp, wat); 
                        wasm = execSync(`wat2wasm ${temp} ${options.join(" ")} --output=-`);
                        file ? writeFileSync(file, wasm) : file = "stdout";
                        unlinkSync(temp); 
                    } catch (e) { throw e; }

                    if (dump_module) {
                        console.log(wat);
                    }
                    
                    return Object.assign(wasm, {output: file});
                } 
            }
        });
    },

    get (target, prop) {
        if (prop === Symbol.toPrimitive) return () => path;
        return createProxy(path?.concat(".", prop) || prop);
    }
});

export const wat = createProxy(), {
    i32, f32, i64, f64, v128, 
    extern, externref, funcref, shared,
    func, start, type, param, result,
    local, global,
    ref, data, elem, 
    table, memory, 
    call, call_indirect, select,
    loop, br, br_if, drop, nop, unreachable
} = wat;

export default wat;
