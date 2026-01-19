import helpers from "../helpers.js"

export const ASYNC_BLOCK_NAME = "async";

export default function (wat, WAT4WASM) {

    const maskSet = new helpers.MaskSet(wat);
    const inlineFunctions = new Array();

    while (maskSet.hasBlock(ASYNC_BLOCK_NAME)) {
        const block = maskSet.lastBlockOf(ASYNC_BLOCK_NAME);
        const result = block.blockName.split(".").at(1) || "";

        let chain, step, $exit, $name, $prop, $func,
            steps = new helpers.MaskSet(block);

        steps.mask(chain = steps.parseFirstBlock());
        maskSet.mask(block);

        while (steps.hasAnyBlock) {
            steps.mask(step = steps.parseFirstBlock());

            $prop = step.blockName;
            $func = step.rawContent;
            $exit = steps.hasAnyBlock && "ext" || result;

            if ($func.startsWith("ref.func")) {
                $name = `$${$func.split("ref.func").pop().trim()}`;
            } else {
                $name = `$${$prop}_${block.begin}_${step.begin}`;
                inlineFunctions.push(`(func ${$name}\n${$func}\n)`);
            }

            chain = String(`
            (call $self.Reflect.apply<ext.ext.ext>${$exit}
                (ref.extern $self.Promise.prototype.${$prop}<ext>)
                ${chain.toString()}
                (call $self.Array.of<fun>ext (ref.func ${$name}))
            )`);
        }

        maskSet.update(block, chain);
    }


    wat = maskSet.restore();

    if (inlineFunctions.length) {
        wat = helpers.append(wat, inlineFunctions.join("\n\n"));
    }

    return wat;
}