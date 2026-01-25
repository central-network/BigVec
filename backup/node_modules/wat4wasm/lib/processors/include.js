import helpers from "../helpers.js"

export const INCLUDE_BLOCK_NAME = "include";

export default function (wat, WAT4WASM) {

    while (helpers.hasBlock(wat, INCLUDE_BLOCK_NAME)) {
        const block = helpers.lastBlockOf(wat, INCLUDE_BLOCK_NAME);
        const path = helpers.findQuotedText(block);

        wat = block.replacedRaw(
            helpers.readFileAsText(path)
        );
    }

    return wat;
}