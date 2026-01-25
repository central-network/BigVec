import helpers from "../helpers.js"

export let WAT4WASM_$NAME = `$wat4wasm`;

export let WAT4WASM_FUNC = String(`
    (func $wat4wasm 
        (local $textDecoder externref)
        (local $textDecoder.decode externref)
        (local $Uint8Array externref)
        (local $arguments externref)
        (local $arrayBufferView externref)

        (local $viewAt i32)
        (local $offset i32)
        (local $length i32)

        (block $prepare
            (local.set $textDecoder
                (call $self.Reflect.construct<ext.ext>ext
                    (call $self.Reflect.get<ext.ext>ext
                        (self) 
                        (string "TextDecoder")
                    )
                    (self)
                )
            )

            (local.set $textDecoder.decode
                (call $self.Reflect.get<ext.ext>ext
                    (local.get $textDecoder)
                    (string "decode")
                )
            )

            (local.set $Uint8Array
                (call $self.Reflect.get<ext.ext>ext
                    (self) 
                    (string "Uint8Array")
                )
            )
        )

        ;;secure zero heap for memory.init
        (i32.const 0)
        (i32.load (i32.const 0))
        ;; offset and value stacked now 

        (block $oninit)
        (block $ontextready)
        (block $onexternready)
        
        ;; restore zero heap value
        (i32.store (; stack stack ;))
        (nop)
    )
`);

export let WAT4WASM_GLOBAL = String(
    `(global $wat4wasm (mut externref) (ref.null extern))`
);

export let WAT4WASM_TABLE = (size = 1) => String(
    `(table $wat4wasm ${size} externref)`
);

export let WAT4WASM_DATA = (buff = "0000") => String(
    `(data $wat4wasm "${Buffer.from(buff).toString("hex").replaceAll(/(..)/g, `\\$1`)}")`
);

export let WAT4WASM_ELEM = String(
    `(elem $wat4wasm declare func)`
);

export let WAT4WASM_MEMORY = String(
    `(memory $wat4wasm 1)`
);

export let WAT4WASM_START = String(
    `(start $wat4wasm)`
);

export const WAT4WASM_BLOCKS = {
    global: WAT4WASM_GLOBAL,
    table: WAT4WASM_TABLE(1),
    elem: WAT4WASM_ELEM,
    func: WAT4WASM_FUNC,
    data: WAT4WASM_DATA(),
};

export function FUNC_WAT4WASM(wat) {
    return helpers.lastBlockOf(wat, "func", { $name: "$wat4wasm" });
}

export function ELEM_WAT4WASM(wat) {
    const block = helpers.lastBlockOf(wat, "elem", { $name: "$wat4wasm" });
    return block && Object.assign(block, {
        isInitial: helpers.generateId(block) === helpers.generateId(WAT4WASM_ELEM)
    });
}

export function MEMORY_WAT4WASM(wat) {
    return helpers.lastBlockOf(wat, "memory", { $name: "$wat4wasm" });
}

export function GLOBAL_WAT4WASM(wat) {
    return helpers.lastBlockOf(wat, "global", { $name: "$wat4wasm" });
}

export function START_WAT4WASM(wat) {
    return helpers.lastBlockOf(wat, "start", { $name: "$wat4wasm" });
}

export function FUNC_WAT4WASM_NOBLOCKS(wat) {
    const maskSet = new helpers.MaskSet(FUNC_WAT4WASM(wat));

    maskSet.remove(maskSet.lastBlockOf("block", { name: "onexternready" }));
    maskSet.remove(maskSet.lastBlockOf("block", { name: "ontextready" }));
    maskSet.remove(maskSet.lastBlockOf("block", { name: "oninit" }));
    maskSet.remove(maskSet.lastBlockOf("block", { name: "prepare" }));

    return maskSet.restore();
}


export function FUNC_WAT4WASM_BLOCK_ONINIT(wat) {
    const wat4func = FUNC_WAT4WASM(wat);
    const blockoninit = helpers.lastBlockOf(wat4func, "block", { name: "oninit" });
    const $blockoninit = helpers.parseBlockAt(wat, wat4func.begin + blockoninit.begin);

    return $blockoninit;
}

export function FUNC_WAT4WASM_BLOCK_ONTEXTREADY(wat) {
    const wat4func = FUNC_WAT4WASM(wat);
    const ontextready = helpers.lastBlockOf(wat4func, "block", { name: "ontextready" });
    const $ontextready = helpers.parseBlockAt(wat, wat4func.begin + ontextready.begin);

    return $ontextready;
}

export function FUNC_WAT4WASM_BLOCK_ONEXTERNREADY(wat) {
    const wat4func = FUNC_WAT4WASM(wat);
    const onexternready = helpers.lastBlockOf(wat4func, "block", { name: "onexternready" });
    const $onexternready = helpers.parseBlockAt(wat, wat4func.begin + onexternready.begin);

    return $onexternready;
}

export function APPEND_ON_INIT(wat, block) {
    const oninitblock = FUNC_WAT4WASM_BLOCK_ONINIT(wat);

    if (oninitblock.includes(block.toString())) {
        return wat;
    }

    wat = oninitblock.replacedRaw(
        helpers.append(oninitblock, block)
    );

    return wat;
}

export function APPEND_ON_TEXT_READY(wat, block) {
    const ontextready = FUNC_WAT4WASM_BLOCK_ONTEXTREADY(wat);

    if (ontextready.hasBlock("block",
        { $name: helpers.firstBlockOf(block, "block")?.$name }
    ) === false && !ontextready.includes(block.trim())) {
        return ontextready.replacedRaw(
            helpers.append(ontextready, block)
        );
    }

    return wat;
}

export function APPEND_ON_EXTERN_READY(wat, block) {
    const onexternready = FUNC_WAT4WASM_BLOCK_ONEXTERNREADY(wat);

    if (onexternready.includes(block.toString())) {
        return wat;
    }

    wat = onexternready.replacedRaw(
        helpers.append(onexternready, block)
    );

    return wat;
}


export function TABLE_WAT4WASM(wat) {
    const wat4table = helpers.lastBlockOf(wat, "table", { $name: "$wat4wasm" });
    const lastIndex = parseInt(wat4table.toString().match(/\s(\d+)/).pop());

    return wat4table && Object.assign(wat4table, {
        lastIndex, isInitial: lastIndex === 1
    })
}

export function WAT4WASM_GROW_EXTERN_TABLE(wat) {
    const wat4table = TABLE_WAT4WASM(wat);
    const lastIndex = wat4table.lastIndex;

    return {
        index: lastIndex,
        getter: `(table.get $wat4wasm (i32.const ${lastIndex}))`,
        generateSetter: value => `(table.set $wat4wasm (i32.const ${lastIndex}) ${value.toString()})`,
        modifiedRaw: wat4table.replacedRaw(WAT4WASM_TABLE(lastIndex + 1))
    };
}


export function WAT4WASM_REFERENCE_FUNC_ELEMENT(wat, $name) {
    const $wat4elem = ELEM_WAT4WASM(wat);
    const _wat4elem = $wat4elem.toString();

    if (_wat4elem.includes($name) === false) {
        wat = $wat4elem.replacedRaw(_wat4elem
            .substring(0, _wat4elem.lastIndexOf(")"))
            .concat(` ${$name}`)
            .concat(")")
        );
    }

    return wat;
}


export function DATA_WAT4WASM(wat) {
    const block = helpers.lastBlockOf(wat, "data", { $name: "$wat4wasm" });
    const strhex = helpers.findQuotedText(block);
    const buffer = Buffer.from(strhex.replaceAll(/[^a-f0-9A-F]/g, ""), "hex");

    return Object.assign(block, {
        buffer: buffer,
        offset: buffer.byteLength,
        isInitial: buffer.byteLength === 4
    });
}


export function WAT4WASM_ALLOC_DATA_BUFFER(wat, buffer) {
    const new_data = Buffer.from(buffer);
    const all_data = DATA_WAT4WASM(wat);

    let offset = all_data.buffer.indexOf(new_data);
    let modifiedRaw = wat;
    let isAllocated = offset === -1;

    if (offset < 0) {
        offset = all_data.offset;
        all_data.buffer.writeUint32LE(offset + new_data.byteLength);
        modifiedRaw = all_data.replacedRaw(WAT4WASM_DATA(Buffer.concat([all_data.buffer, new_data])));
    }

    return {
        offset,
        isAllocated,
        modifiedRaw,
        isRawModified: modifiedRaw.toString() !== wat.toString()
    };
}


export default function (wat) {
    let i = 31, raw;

    if (helpers.hasBlock(wat, "memory") === false) {
        WAT4WASM_BLOCKS.memory = WAT4WASM_MEMORY;
    }

    for (const BLOCK_NAME in WAT4WASM_BLOCKS) {
        if (wat.includes(`(${BLOCK_NAME} $wat4wasm`)) {
            continue;
        }

        if (i === 31) console.log("")
        console.log(`🦋 appending element --> \x1b[${i++}m(${BLOCK_NAME} $wat4wasm) ...)\x1b[0m`);

        wat = helpers.append(wat, WAT4WASM_BLOCKS[BLOCK_NAME]);
    }
    if (i !== 31) console.log("")

    return wat;
}