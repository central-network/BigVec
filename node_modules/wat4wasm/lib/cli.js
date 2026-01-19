
import fs from "fs";
import { spawnSync } from "child_process";

export async function processCLI(compileCallback, PROCESS = process) {

    console.log("\x1b[31m")
    // Argument Parsing Logic
    const args = PROCESS.argv.slice(2);
    const config = {
        inputFile: null,
        outputFile: null,
        wat2wasmPath: null,
        unlinkWat4FileIfCompilationSuccess: true,
        windowtagName: "",
        defaultTagName: "🦋",
        keepChromeGlobal: false,
        keepHTMLDocument: false,
        keepWindowTagName: false,
        keepWindowObjects: false,
        keepFaviconRequest: false,
        generateWASMFromHEXString: true,
        generateWASMFromNumberArray: false,
        consoleLogInstance: false,
        faviconLinkHref: "data:null",
        printOnly: false,
        passthroughArgs: [],
        applyScripts: [],
        keepUnusedFunctions: false
    };

    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        if (arg.startsWith("--output=")) {
            config.outputFile = arg.split("=")[1];
        } else if (arg.startsWith("--input=")) {
            config.inputFile = arg.split("=")[1];
        } else if (arg.startsWith("--apply=")) {
            config.applyScripts.push(arg.split("=")[1]);
        } else if (arg.startsWith("--wat2wasm=")) {
            config.wat2wasmPath = arg.split("=")[1];
        } else if (arg.startsWith("--tag=")) {
            config.windowtagName = arg.split("=")[1];
        } else if (arg === "--print-only") {
            config.printOnly = true;
        } else if (arg === "--wasm-from-numbers-array") {
            config.generateWASMFromNumberArray = true;
            config.generateWASMFromHEXString = false;
        } else if (arg === "--wasm-from-hex-string") {
            config.generateWASMFromHEXString = true;
            config.generateWASMFromNumberArray = false;
        } else if (arg === "--untouched-window") {
            config.keepHTMLDocument = true;
            config.keepChromeGlobal = true;
            config.keepWindowObjects = true;
            config.keepFaviconRequest = true;
            config.windowtagName &&= "";
        } else if (arg === "--log-instance") {
            config.consoleLogInstance = true;
        } else if (arg === "--keep-unused-functions") {
            config.keepUnusedFunctions = true;
        } else if (arg === "--keep-window") {
            config.keepWindowObjects = true;
        } else if (arg === "--keep-chrome-global") {
            config.keepChromeGlobal = true;
        } else if (arg === "--keep-document") {
            config.keepHTMLDocument = true;
        } else if (arg === "--keep-favicon") {
            config.keepFaviconRequest = true;
        } else if (arg === "--no-unlink") {
            config.unlinkWat4FileIfCompilationSuccess = false;
        } else if (arg.startsWith("-")) {
            // Collect flags to pass to wat2wasm
            config.passthroughArgs.push(arg);
        } else {
            if (!config.inputFile) {
                config.inputFile = arg;
            } else {
                console.warn(`Warning: Ignoring extra argument '${arg}'`);
            }
        }
    }

    if (!config.inputFile) {
        console.error("Error: Input file required! Usage: wat4wasm <input.wat> [options]");
        PROCESS.exit(1);
    }

    config.inputDirectory = process
        .cwd()
        .replaceAll("file://", "")
        .concat(config
            .inputFile
            .split("/")
            .reverse().slice(1)
            .reverse()
            .join("/")
        )
        .concat("/")
        .replaceAll("//", "/");

    const isJSTarget = config.outputFile?.endsWith(".js");
    const isHTMLTarget = config.outputFile?.endsWith(".html");

    if (isHTMLTarget || isJSTarget) {
        config.outputFile = config.outputFile.substring(
            0, config.outputFile.lastIndexOf(".")
        ).concat(".wat");
    }

    // Default output file if not specified (and not printing only)
    if (!config.outputFile && !config.printOnly) {
        config.outputFile = config.inputFile.replace(/\.wat$/, "-output.wat");
    }

    try {
        console.log(`\x1b[0m\x1b[33m🚀 Wat4Wasm: Processing ${config.inputFile}...\x1b[0m`);
        if (!fs.existsSync(config.inputFile)) {
            throw new Error(`Input file not found: ${config.inputFile}`);
        }

        const rawCode = fs.readFileSync(config.inputFile, "utf8");
        const applyScripts = await Array.fromAsync(
            config.applyScripts.map(script => Object({
                basename: script.split("/").pop().split(".").reverse().slice(1).reverse().join("."),
                fullpath: config.inputDirectory.concat(script)
            })).map(async script => Object.assign(script, {
                function: await import(script.fullpath).then(s => s.default)
            }))
        );

        config.APPLY = async function APPLY(code) {
            let script, i = applyScripts.length;
            while (script = applyScripts[--i]) {
                const wat2 = await script.function.call(null, code);
                const func = script.basename;
                const diff = code.toString().length - wat2.toString().length;

                if (diff) {
                    console.log(`\x1b[0m\x1b[34m🎸 \x1b[35m${func}(\x1b[0mwat\x1b[35m)\x1b[0m \x1b[32m-->\x1b[0m \x1b[35m${diff}\x1b[0m byte(s)\x1b[0m`)
                }

                code = wat2;
            }
            return code;
        }
        // 2. Call the provided compile function
        const compiled = await compileCallback(rawCode, config);
        console.log("\x1b[0m")

        // 3. Handle Output
        if (config.printOnly) {
            console.log("\x1b[0m\x1b[33m--- Compiled Output ---");
            console.log(compiled);
            console.log("-----------------------\x1b[0m");
            return;
        }

        // Write compiled WAT (or temp WAT for WASM target)
        let watFile = config.outputFile;
        let wasmFile = config.outputFile.substring(
            0, config.outputFile.lastIndexOf(".")
        ).concat(".wasm");


        const isWasmTarget = isJSTarget || isHTMLTarget || config.outputFile.endsWith(".wasm") || config.wat2wasmPath;

        if (isWasmTarget && config.outputFile.endsWith(".wasm")) {
            // If target is WASM, write WAT to a temp file
            watFile = config.outputFile + ".wat";
        }

        fs.writeFileSync(watFile, compiled);
        console.log(`\x1b[0m\x1b[36m✅ WAT Written to: ${watFile}\n`);

        // Run wat2wasm if requested
        if (config.wat2wasmPath || isHTMLTarget || isJSTarget) {
            console.log(`\x1b[0m\x1b[32m🔨 Running wat2wasm...`);

            // If user explicitly set .wasm output but output file was .wat? 
            // The logic above sets wasmFile = config.outputFile.
            // If config.outputFile was "out.wat", then we overwrite it with "out.wasm"? 
            // Standard wat2wasm behavior takes -o <file>.
            // Our config.outputFile came from --output.

            const cmdArgs = [watFile, ...config.passthroughArgs, "--output", wasmFile];
            console.log(`\x1b[0m\x1b[32m   Command: ${config.wat2wasmPath} ${cmdArgs.join(" ")}\n`);

            const result = spawnSync(config.wat2wasmPath, cmdArgs, { stdio: "inherit" });

            if (result.status === 0) {
                console.log(`\x1b[0m\x1b[35m🎉 WASM Build Successful: ${wasmFile}`);

                if (config.unlinkWat4FileIfCompilationSuccess && watFile !== wasmFile) {
                    try { fs.unlinkSync(watFile); } catch (e) { }
                }

                if (isJSTarget || isHTMLTarget) {
                    const wasmhex = fs.readFileSync(wasmFile, "hex");

                    let extension = "";
                    let filecontent = "";

                    if (isJSTarget) {

                        let wasmGenerator = ``;
                        if (config.generateWASMFromHEXString && !config.generateWASMFromNumberArray) {
                            wasmGenerator = `Uint8Array.from(\`${wasmhex}\`.match(/../g), $ => parseInt($, 16))`;
                        }
                        else if (!config.generateWASMFromHEXString && config.generateWASMFromNumberArray) {
                            wasmGenerator = `Uint8Array.of(${wasmhex.toString().match(/[a-f0-9]{2}/g).map(h => parseInt(h, 16))})`;
                        }

                        extension = "js";
                        filecontent = String(`
                            const view = ${wasmGenerator};
                            export let wasm = view.buffer;
                            
                            wasm.module = null;
                            wasm.instances = new Array;
                            
                            const compile = async () => WebAssembly.compile(wasm).then(m => {
                                wasm.module = m;
                                return wasm;
                            });
                            
                            const instantiate = async () => WebAssembly.instantiate(wasm.module, self).then(i => {
                                wasm.instances.push(i);    
                                return i;
                            });
                            
                            wasm.spawn = async imports => {
                                if (wasm.module instanceof WebAssembly.Module === false) {
                                    Object.assign(self, Object(imports));
                                    return compile().then(() => instantiate());
                                } 
                                return instantiate();
                            };
                            
                            export default wasm;`);

                        filecontent = filecontent.replaceAll(
                            String(" ").repeat(filecontent.search(/\w/) - 1), ""
                        );
                    }
                    else {
                        extension = "html";
                        const thenCalls = [];

                        if (config.consoleLogInstance) {
                            thenCalls.push(`console.warn(wasm)`);
                        }

                        if (!config.keepHTMLDocument) {
                            thenCalls.push(`Array.from(document.children).forEach(i => i.remove())`);
                        }

                        if (!config.keepChromeGlobal && !config.keepWindowObjects) {
                            thenCalls.push(`self.chrome && (self.chrome = self)`)
                        }

                        const windowTag = config.windowtagName || config.defaultTagName;
                        if ((!config.keepWindowTagName && !config.keepWindowObjects) || config.windowtagName) {
                            thenCalls.push(`Reflect.defineProperty(__proto__, Symbol.toStringTag, {value: String.fromCharCode(${windowTag.split("").map(c => c.charCodeAt())}) })`)
                        }

                        if (!config.keepWindowObjects) {
                            thenCalls.push(`Reflect.ownKeys(self).forEach(Reflect.deleteProperty.bind(Reflect, self))`);
                        }

                        const thenCall = thenCalls.length && String(`.then(wasm => [${thenCalls}])`) || String();

                        let wasmGenerator = ``;
                        if (config.generateWASMFromHEXString && !config.generateWASMFromNumberArray) {
                            wasmGenerator = `Uint8Array.from(\`${wasmhex}\`.match(/../g), $ => parseInt($, 16))`;
                        }
                        else if (!config.generateWASMFromHEXString && config.generateWASMFromNumberArray) {
                            wasmGenerator = `Uint8Array.of(${wasmhex.toString().match(/[a-f0-9]{2}/g).map(h => parseInt(h, 16))})`;
                        }

                        const onload = [
                            `WebAssembly.instantiate(${wasmGenerator}, self)`.concat(thenCall)
                        ];

                        if (!config.keepFaviconRequest && config.faviconLinkHref) {
                            const faviconHTML = `<link rel=icon href=${config.faviconLinkHref}>`;
                            onload.push(`Reflect.set(document.head, String.fromCharCode(${'innerHTML'.split("").map(c => c.charCodeAt())}), String.fromCharCode(${faviconHTML.split("").map(c => c.charCodeAt())}))`)
                        }

                        filecontent = `<body onload="[${onload}]"></body>`;
                    }

                    const filename = wasmFile
                        .substring(0, wasmFile.lastIndexOf("."))
                        .concat(".")
                        .concat(extension);

                    fs.writeFileSync(filename, filecontent);

                    if (config.unlinkWat4FileIfCompilationSuccess) {
                        try { fs.unlinkSync(wasmFile); } catch (e) { }
                    }
                }

            } else {
                console.error(`💥 wat2wasm failed with exit code ${result.status}`);
                PROCESS.exit(result.status);
            }
        }

    } catch (err) {
        console.error(`\n💥 ERROR:`, err);
        PROCESS.exit(1);
    } finally {
        console.log("\x1b[0m")
    }
}
