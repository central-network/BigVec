import helpers from "../helpers.js"

export const IMPORT_BLOCK_NAME = "import";

const RAWBLOCK_IMPORT_CODE = (pathName, rawBlock) => `(import "${pathName.split(".").at(-2) || 'self'}" "${pathName.split(".").at(-1)}"  \t${rawBlock})`.replaceAll(" )", ")");
const FUNCTION_IMPORT_CODE = ($name) => {
    const namesig = $name.match(/\$(.[^<]*)<(.[^>]*)?>(.[^\s]*)?/).slice(1);
    const [pathName, inputs = "", outputs = ""] = namesig;

    const tagName = `func`;
    const longType = t => ({ ext: 'externref', fun: 'funcref' })[t] || t;
    const paramBlock = `(param${`.${inputs}`.split('.').map(longType).join(' ')})`;
    const resultBlock = `(result${`.${outputs}`.split('.').map(longType).join(' ')})`;

    return RAWBLOCK_IMPORT_CODE(pathName, `(${tagName} ${$name} ${paramBlock} ${resultBlock})`);
}

const GLOBAL_IMPORT_CODE = ($name) => {
    const namesig = $name.match(/\$(.[^<]*)(?:\<(.[^>]*)\>)?/)?.slice(1) || [];
    const [pathName = "self", type = "ext"] = namesig;

    const tagName = "global";
    const typeName = type.replace(`ext`, `externref`);

    return RAWBLOCK_IMPORT_CODE(pathName, `(${tagName} ${$name} ${typeName})`);
}

const GLOBAL_DEFINE_CODE = ($name) => {
    const [pathName = "self", type = "ext"] = helpers.nameSignatureofGlobal($name);

    const tagName = "global";
    const mutValue = t => `(mut ${({ ext: 'externref', fun: 'funcref' })[t] || t})`;
    const nilValue = t => `(${({ ext: 'ref.null extern', fun: 'ref.null func' })[t] || `${t}.const 0`})`;

    return `(${tagName} ${$name} ${mutValue(type)} ${nilValue(type)})`;
}

export const PATH_WALKER_CODE = ($name) => {

    let descriptorKey;
    [$name, descriptorKey = "value"] = $name.split("/")
    const nameparts = $name.split("<").at(0).split("$").pop().split(".");
    const stepType = new Array(nameparts.length - 1).fill("ext");
    const type = $name.split(">").at(0).split("<").pop() || "ext";

    let pathWalker = `(global.get $${nameparts[0]})`;
    let currentKey;

    stepType.push(type);
    stepType.reverse().pop();
    nameparts.reverse().pop();

    let stepCount = nameparts.length;
    if (descriptorKey !== "value") {
        stepCount = stepCount - 1;
    }

    while (stepCount--) {
        currentKey = nameparts.pop();
        pathWalker = String(`
        (call $self.Reflect.get<ext.ext>${stepType.pop()}
            ${pathWalker} 
            (text "${currentKey}") ;; ${currentKey}
        )`).trim();
    }

    if (descriptorKey !== "value") {
        currentKey = nameparts.pop();
        pathWalker = String(`
        (call $self.Reflect.get<ext.ext>ext
            (call $self.Reflect.getOwnPropertyDescriptor<ext.ext>ext
                ${pathWalker} 
                (text "${currentKey}") ;; ${currentKey}
            )
            (text "${descriptorKey}") ;; ${descriptorKey}
        )`).trim();
    }

    return String(`
    ${pathWalker}
    `);
}

export default function (wat, WAT4WASM) {

    const maskSet = new helpers.MaskSet(wat);
    const selfSet = new Set();
    const imports = new Array();
    const globals = new Array();
    const oninits = new Array();

    while (maskSet.hasBlock(IMPORT_BLOCK_NAME)) {
        const wrapper = maskSet.lastBlockOf(IMPORT_BLOCK_NAME);
        const $name = helpers.parseFirstBlock(wrapper).$name;

        if ($name && $name.startsWith("$self")) {
            if (selfSet.has($name) === false) {
                selfSet.add($name);
            }
        }

        maskSet.mask(wrapper);
    }

    while (maskSet.hasBlock("global.get")) {
        const global = maskSet.lastBlockOf("global.get");
        const $name = global.$name;

        maskSet.mask(global);
        maskSet.update(global, `(global.get ${$name})`);

        if ($name && $name.startsWith("$self")) {
            if (selfSet.has($name) === false) {
                selfSet.add($name);

                const [pathName = "self", type = "ext"
                ] = helpers.nameSignatureofGlobal($name);

                const nameparts = pathName.split(".");

                /**
                 * previous logic is based on direct import for
                 * short paths but this is unnecessary.. just set
                 * global value in the start function to gathering
                 * more simple import segment. 
                 */
                //if (nameparts.length <= 3) {
                if (["$self", "$self.String.fromCharCode"].includes($name)) {
                    imports.push(GLOBAL_IMPORT_CODE($name));
                }
                else if (globals.includes($name) === false) {
                    globals.push(GLOBAL_DEFINE_CODE($name));
                    const walker = PATH_WALKER_CODE($name, global.descriptorKey);
                    const setter = `(global.set ${$name} ${walker})`;
                    oninits.push({ setter, name: $name.substring(1), type: 'global' });
                }
            }
        }
    }

    while (maskSet.hasBlock("call")) {
        const caller = maskSet.lastBlockOf("call");
        const $name = caller.$name;

        if ($name && $name.startsWith("$self")) {
            if (selfSet.has($name) === false) {
                selfSet.add($name);
                imports.push(FUNCTION_IMPORT_CODE($name));
            }
        }

        maskSet.mask(caller);
    }

    wat = maskSet.restore();

    imports.forEach(code => {
        if (wat.includes(code) === false) {
            wat = helpers.prepend(wat, code);
        }
    });

    globals.forEach(code => {
        if (wat.includes(code) === false) {
            wat = helpers.append(wat, code);
        }
    });

    oninits.forEach(init => {
        const header = `block $${init.type}/${init.name}`;
        if (wat.includes(header) === false) {
            const code = String(`(${header}\n${init.setter}\n)`);
            wat = APPEND_ON_TEXT_READY(wat, code);
        }
    });

    return wat;
}