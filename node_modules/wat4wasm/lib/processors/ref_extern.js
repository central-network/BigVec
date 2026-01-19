import helpers from "../helpers.js"
import { PATH_WALKER_CODE } from "./import.js";

export const REF_EXTERN_BLOCK_NAME = "ref.extern";

const FIXNAME_SELF_PATH = ($name, descriptorKey) => {

    if ($name.startsWith("$self") === false) {
        $name = `$self.${$name.substring(1)}`;
    }

    if ($name.endsWith(">") === false) {
        if (descriptorKey === "value") {
            $name = `${$name}<ext>`;
        }
    }

    return $name;
};

export default function (wat, WAT4WASM) {

    const externs = new Map();
    const getters = new Map();
    const maskSet = new helpers.MaskSet(wat);

    while (maskSet.hasBlock(REF_EXTERN_BLOCK_NAME)) {
        const block = maskSet.lastBlockOf(REF_EXTERN_BLOCK_NAME);
        const $name = FIXNAME_SELF_PATH(block.$name, block.descriptorKey);

        if (externs.has($name) === false) {
            externs.set($name, block.descriptorKey);
        }

        maskSet.mask(block);
    }

    wat = maskSet.restore();

    let oninit = String();
    externs.forEach((dKey, $name) => {
        const pathWalker = PATH_WALKER_CODE($name);
        const growExtern = WAT4WASM_GROW_EXTERN_TABLE(wat);

        const __getter__ = growExtern.getter.concat(` ;; ${$name}\n`);
        const __setter__ = growExtern.generateSetter(pathWalker);

        wat = growExtern.modifiedRaw;
        oninit = `${oninit}\n\n(block ${$name}\n${__setter__})\n`;
        getters.set($name, __getter__);
    });

    while (helpers.hasBlock(wat, REF_EXTERN_BLOCK_NAME)) {
        const block = helpers.lastBlockOf(wat, REF_EXTERN_BLOCK_NAME);
        const $name = FIXNAME_SELF_PATH(block.$name, block.descriptorKey);
        wat = block.replacedRaw(getters.get($name));
    }

    if (oninit.trim()) {
        wat = APPEND_ON_TEXT_READY(wat, oninit);
    }

    return wat;
}