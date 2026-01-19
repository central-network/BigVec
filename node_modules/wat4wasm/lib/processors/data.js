import helpers from "../helpers.js"

export const DATA_BLOCK_NAME = "data";
export const SIZE_BLOCK_NAME = "data.size";
export const VIEW_BLOCK_NAME = "data.view";

const GENERATE_DATA_VIEWER = (size, $name) => {
    return `
    (block ${$name}>
        (result externref)

        (global.set $wat4wasm (call $self.Array<>ext))
        
        (call $self.Reflect.set<ext.i32.i32>
            (global.get $wat4wasm) (i32.const 0) (i32.const ${size})
        )

        (global.set $wat4wasm
            (call $self.Reflect.construct<ext.ext>ext
                (ref.extern $self.Uint8Array<ext>)
                (global.get $wat4wasm)
            )
        )
        
        (if (i32.const ${size})
            (then
                (i32.const 0)
                (i64.load (i32.const 0))

                (block $copy
                    (i32.store (i32.const 0) (i32.const ${size}))
                    (loop $i--
                        (if (i32.load (i32.const 0))
                            (then   
                                (i32.store
                                    (i32.const 0)
                                    (i32.sub (i32.load (i32.const 0)) (i32.const 1))
                                )

                                (memory.init ${$name} 
                                    (i32.const 4) 
                                    (i32.load (i32.const 0)) 
                                    (i32.const 1)
                                )

                                (call $self.Reflect.set<ext.i32.i32>
                                    (global.get $wat4wasm)
                                    (i32.load (i32.const 0))
                                    (i32.load8_u (i32.const 4))
                                )

                                (br $i--)
                            )
                        )
                    )
                )

                (i64.store (; stack stack ;))
            )
        )

        (global.get $wat4wasm)
        (global.set $wat4wasm (null))
    )
    `;
};

export default function (wat, WAT4WASM) {

    const maskSet = new helpers.MaskSet(wat);

    const externgetter = new Map();
    const segmentSizes = new Map();
    const sizeRequests = new Set();
    const viewRequests = new Set();

    while (maskSet.hasBlock(VIEW_BLOCK_NAME)) {
        const block = maskSet.lastBlockOf(VIEW_BLOCK_NAME);
        viewRequests.add(block);
        maskSet.mask(block);
    }

    while (maskSet.hasBlock(SIZE_BLOCK_NAME)) {
        const block = maskSet.lastBlockOf(SIZE_BLOCK_NAME);
        sizeRequests.add(block);
        maskSet.mask(block);
    }

    while (maskSet.hasBlock(DATA_BLOCK_NAME)) {

        const block = maskSet.lastBlockOf(DATA_BLOCK_NAME);
        const content = helpers.findQuotedText(block);

        maskSet.mask(block);
        if (helpers.hasProtocol(content) === false) {
            continue;
        }

        let {
            protocol, fullpath, directory,
            filename, basename, extension
        } = helpers.parseProtoPath(content);

        if (protocol === "wasm://") {

            const module_wat = `wat4wasm-${basename}.wat`;
            const wasm_output = `wat4wasm-${basename}.wasm`;
            const wat4wasm_out = `wat4wasm-${basename}.wasm.wat`;

            const params = process.argv
                .filter(a => a.startsWith("--"))
                .filter(a => !a.startsWith("--input="))
                .filter(a => !a.startsWith("--output="))
                ;

            helpers.copyFile(fullpath, module_wat)

            const wat4wasm = process.argv[1];
            const nodejs = process.argv[0];
            const argv = Array.of(
                wat4wasm,
                `--input=${module_wat}`,
                `--output=${wasm_output}`,
                `--no-unlink`
            ).concat(params);

            helpers.spawnSync(nodejs, argv);

            const { data, size } = helpers.readFileAsHex(wasm_output);

            segmentSizes.set(block.$name, size);
            maskSet.update(block, block.replace(content, data));

            helpers.unlinkFile(module_wat);
            helpers.unlinkFile(wasm_output);
            helpers.unlinkFile(wat4wasm_out);
        }

        else if (protocol === "file://") {
            const { data, size } = helpers.readFileAsHex(fullpath);
            segmentSizes.set(block.$name, size);
            maskSet.update(block, block.replace(content, data));
        }
    }

    sizeRequests.forEach(block => {
        const size = segmentSizes.get(block.$name);
        const code = `(i32.const ${size})`;

        maskSet.update(block, code);
    });

    viewRequests.forEach(block => {
        block.id = helpers.referenceId();
        maskSet.update(block, block.id);
    });

    wat = maskSet.restore();

    let oninit = String();
    viewRequests.forEach(block => {
        if (externgetter.has(block.$name) === false) {
            const size = segmentSizes.get(block.$name);
            const code = GENERATE_DATA_VIEWER(size, block.$name);

            const growRequest = WAT4WASM_GROW_EXTERN_TABLE(wat);
            block.tableSetter = growRequest.generateSetter(code);

            wat = growRequest.modifiedRaw;
            oninit = `${oninit}\n\n${block.tableSetter}\n\n`;

            externgetter.set(
                block.$name,
                growRequest.getter.concat(` ;; ${block.$name}\n`)
            );
        }
    });

    viewRequests.forEach(block => {
        wat = wat.replaceAll(
            block.id, externgetter.get(block.$name)
        );
    });

    wat = APPEND_ON_EXTERN_READY(wat, oninit);

    return wat;
}