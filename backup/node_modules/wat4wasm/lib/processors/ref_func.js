import helpers from "../helpers.js"

export const REF_FUNC_BLOCK_NAME = "ref.func";

export default function (wat, WAT4WASM) {

    const inlineFunctions = new Array();

    helpers
        .parseBlockAt(wat.toString(), 0)
        .children
        .filter(b => b.startsWith("(func"))
        .filter(b => b.substring(1).includes("(func"))
        .map(b => b.substring(5, b.length - 1).trim())
        .forEach(content => {
            const maskSet = new helpers.MaskSet(content);
            while (maskSet.hasBlock("func")) {
                const inl = maskSet.lastBlockOf("func");
                inlineFunctions.push(helpers.parseBlockAt(inl.toString(), 0));
                maskSet.mask(inl);
            }
        })
        ;

    if (inlineFunctions.length) {
        inlineFunctions.forEach(func => {
            wat = wat.replace(func.toString(), `(ref.func ${func.$name})`)
        });
        wat = helpers.append(wat, inlineFunctions.map(func => `\n\t${func}\n`).join("\n"));
    }

    const maskSetElem = new helpers.MaskSet(wat);
    const elemSegments = new Array();
    const needReference = new Set();

    while (maskSetElem.hasBlock("elem")) {
        const block = maskSetElem.lastBlockOf("elem");
        const $name = block.$name;
        if ("$wat4wasm" !== $name) {
            elemSegments.push(block.toString());
        }
        maskSetElem.mask(block);
    }

    const maskSetRef = new helpers.MaskSet(wat);

    while (maskSetRef.hasBlock(REF_FUNC_BLOCK_NAME)) {
        const block = maskSetRef.lastBlockOf(REF_FUNC_BLOCK_NAME);
        const $name = block.$name

        if ("$wat4wasm" !== $name) {
            if (elemSegments.some(seg => seg.includes($name)) === false) {
                if (needReference.has($name) === false) {
                    needReference.add($name);
                }
            }
        }

        maskSetRef.mask(block);
    }

    wat = maskSetRef.restore();

    needReference.forEach($name => {
        wat = WAT4WASM_REFERENCE_FUNC_ELEMENT(wat, $name);
    });

    return wat;
}