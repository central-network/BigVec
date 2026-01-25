import { FUNC_WAT4WASM_BLOCK_ONEXTERNREADY } from "./processors/wat4wasm.js"
import { FUNC_WAT4WASM_BLOCK_ONTEXTREADY } from "./processors/wat4wasm.js"
import { FUNC_WAT4WASM_BLOCK_ONINIT } from "./processors/wat4wasm.js"
import { ELEM_WAT4WASM } from "./processors/wat4wasm.js"
import { TABLE_WAT4WASM } from "./processors/wat4wasm.js"
import { DATA_WAT4WASM } from "./processors/wat4wasm.js"
import { MEMORY_WAT4WASM } from "./processors/wat4wasm.js"
import { START_WAT4WASM } from "./processors/wat4wasm.js"
import { FUNC_WAT4WASM } from "./processors/wat4wasm.js"

function FUNC_WAT4WASM_START_CALLS(wat) {
    let $call;
    const calls = [];
    const maskSet = new helpers.MaskSet(
        FUNC_WAT4WASM_NOBLOCKS(wat)
    );

    while ($call = maskSet.lastBlockOf("call")) {
        if (calls.includes($call.$name) === false) {
            calls.push($call.$name);
        }
        maskSet.mask($call);
    }

    return calls;
}

export default function (wat, config = {}) {
    console.log("")
    let block, $name;
    block = FUNC_WAT4WASM_BLOCK_ONEXTERNREADY(wat);
    if (!block.hasAnyBlock) { wat = block.removedRaw(); }
    block = FUNC_WAT4WASM_BLOCK_ONTEXTREADY(wat);
    if (!block.hasAnyBlock) { wat = block.removedRaw(); }
    block = FUNC_WAT4WASM_BLOCK_ONINIT(wat);
    if (!block.hasAnyBlock) {
        wat = block.removedRaw();
        let $starts = FUNC_WAT4WASM_START_CALLS(wat);
        if ($starts.length === 1) {
            const $start = $starts.pop();
            wat = wat.replace(`(start $wat4wasm)`, `(start ${$start})`);
            console.log(`⚠️  replaced --> \x1b[34m(start \x1b[35m$wat4wasm\x1b[0m --> \x1b[35m${$start}\x1b[0m)\x1b[0m`);
        }
        else if ($starts.length === 0) {
            console.log(`⚠️  removing --> \x1b[34m(start \x1b[35m$wat4wasm\x1b[0m)\x1b[0m`);
            wat = wat.replace(`(start $wat4wasm)`, ``);
        }
        let $func = FUNC_WAT4WASM(wat);
        if ($func) {
            console.log(`⚠️  removing --> \x1b[34m(func \x1b[35m$wat4wasm\x1b[0m ...)\x1b[0m`);
            wat = $func.removedRaw();
        }
        block = ELEM_WAT4WASM(wat);
        if (block.isInitial) {
            console.log(`⚠️  removing --> \x1b[34m(elem \x1b[35m$wat4wasm\x1b[0m ...)\x1b[0m`);
            wat = block.removedRaw();
        }
        block = DATA_WAT4WASM(wat);
        if (block.isInitial) {
            console.log(`⚠️  removing --> \x1b[34m(data \x1b[35m$wat4wasm\x1b[0m ...)\x1b[0m`);
            wat = block.removedRaw();
        }
        block = TABLE_WAT4WASM(wat);
        if (block.isInitial) {
            console.log(`⚠️  removing --> \x1b[34m(table \x1b[35m$wat4wasm\x1b[0m ...)\x1b[0m`);
            wat = block.removedRaw();
        }
        if (false === helpers.hasBlock(wat, "global.get", { $name: "$wat4wasm" }) &&
            false === helpers.hasBlock(wat, "global.set", { $name: "$wat4wasm" })) {
            console.log(`⚠️  removing --> \x1b[34m(global \x1b[35m$wat4wasm\x1b[0m ...)\x1b[0m`);
            wat = GLOBAL_WAT4WASM(wat).removedRaw();
        }
    }
    const maskSet = new helpers.MaskSet(wat);
    const imports = new Array();
    while (block = maskSet.lastBlockOf("import")) {
        block.$name = helpers.parseFirstBlock(block).$name;
        imports.push(block);
        maskSet.remove(block);
    }
    wat = maskSet.restore();
    wat = helpers.prepend(wat,
        imports
            .filter(b => new RegExp(`\\${b.$name}\(\\s|\\)\)`).test(wat) || b.toString().match(/(memory|table)/))
            .sort((a, b) => helpers.generateId(a) - helpers.generateId(b))
            .map(b => b.toString())
            .join("\n")
    );

    if (!config.keepUnusedFunctions) {
        const funcMask = new helpers.MaskSet(wat);
        const unusedCalls = new Set();
        funcMask.maskAll("import");
        funcMask.maskComments();
        while (block = funcMask.lastBlockOf("func")) {
            funcMask.mask(block);
            if (($name = block.$name)) {
                if (wat.match(new RegExp(`\\\((call|start|ref\\.func)\\s+\\${$name}(\\s|\\\))`))) {
                    continue;
                }
                if (unusedCalls.has($name) === false) {
                    unusedCalls.add($name);
                }
            }
        }
        unusedCalls.forEach($name => {
            const begin = wat.lastIndexOf(`(func ${$name}`);
            const block = helpers.parseBlockAt(wat, begin);
            $name = $name.replace(".prototype.", ":")
            console.log(`⚠️  removing unused --> \x1b[34m(func \x1b[32m${$name}\x1b[0m ...)\x1b[0m`);
            if (block) { wat = block.removedRaw() }
        });
    }
    const nonWat4WasmMemory = wat.replace(WAT4WASM_BLOCKS.memory, "");
    if (nonWat4WasmMemory.match(/\(memory\s+(\$|\d)/)) {
        console.log(`⚠️  removing --> \x1b[34m(memory \x1b[35m$wat4wasm\x1b[0m ...)\x1b[0m`);
        wat = nonWat4WasmMemory;
    }
    console.log("")
    return wat;
}