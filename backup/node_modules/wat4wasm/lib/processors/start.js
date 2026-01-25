import helpers from "../helpers.js"

export const START_BLOCK_NAME = "start";

export default function (wat, WAT4WASM) {
    let startCalls = [];

    wat = wat.replaceAll(/\(main(\s+)(\$.[^\s]*)(\s)/g, `(start$1$2)\n\n(func$1$2$3`)

    let removedWat = wat;
    while (helpers.hasBlock(removedWat, START_BLOCK_NAME)) {
        let block = helpers.lastBlockOf(removedWat, START_BLOCK_NAME);
        removedWat = block.removedRaw();

        if (block.includes("$wat4wasm") === false) {
            startCalls.push(block);
        }
    }

    if (startCalls.length > 0) {
        wat = removedWat;

        let $wat4func = helpers.lastBlockOf(wat, "func", { $name: "$wat4wasm" });
        let funcblock = $wat4func.toString();

        const appends = startCalls.filter(start => {
            let $name = `${start.$name}`;
            let $call = `(call ${$name})`;

            if (helpers.hasBlock(funcblock, "call", { $name }) === false) {
                funcblock = helpers.append(funcblock, $call);
                return true;
            }
        });

        if (appends.length) {
            wat = $wat4func.replacedRaw(funcblock);
        }
    }

    if (!helpers.hasBlock(wat, "start", { $name: "$wat4wasm" })) {
        wat = helpers.append(wat, `(start $wat4wasm)`);
    }

    return wat;
}