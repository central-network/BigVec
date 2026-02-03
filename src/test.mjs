import fs from "fs"
import cp from "child_process"

let wat = fs.readFileSync("g.wat", "utf8");

let ei = 1;
const paths = new Set();
const funcref = new Set();
const externref = new Set();

function addwalk (fullpath) {
    if (paths.has(fullpath)) return;
    paths.add(fullpath)
    console.log(fullpath)
}

const table_count = {
    fun: 1,
    ext: 1
}

let walks = [];
const walkrouter = { self: {} };
const routerlinks = {};

const descriptor_key = new Map();
const table_type = new Map();

const ext = [,];
const fun = [,];
const get = [];
const set = [];
const val = [];

const tables = {
    ["ref.func"] : {},
    ["ref.extern"] : {},
    ["call_direct"] : {},
    ["ref.global"] : {},
};

const walker = new Set();
const blocks = new Object();

Array.from(wat.matchAll(/\((call_direct|ref\.(?:extern|func|global))\s+\$(.[^\s|\)]*)(\s+|\))/g)).forEach(m => {
    delete m.groups;
    delete m.input;

    let fullpath = `self.${m[2]}`;

    fullpath = fullpath.replaceAll("self.self", "self");
    fullpath = fullpath.replaceAll(/\:(.)/g, `.prototype.$1`).replaceAll(/\:/g, `.prototype`)
    fullpath = fullpath.replaceAll(/([A-Z](?:.*)(?:8|16|32|64)(?:.*)Array)(\.prototype\.[a-z]+)/g, "Uint8Array.__proto__$2");
    fullpath = fullpath.concat(`/value`).replace(/\[(get|set|value)\]\/value/g, `/$1`);

    if (m[1] === "ref.func" && wat.match(new RegExp(`\\(func\\s+\\$${m[2]}[\\s|\\)]`, "gm"))) {
        return;
    }

    tables[m[1]][fullpath] ??= new Set();
    tables[m[1]][fullpath].add(m[0].trim());

    walker.add(fullpath);
});


walker.forEach(fullpath => {    
    let block = blocks; 

    fullpath
        .split(".")
        .map((k, i, t) => `$${t.slice(0,i).join(".")}/value`)
        .concat(`$${fullpath}`)
        .slice(1)
        .forEach(s => block = block[s] ??= {})
    ;
});



let blocks_wat = JSON
    .stringify(blocks, null, "    ")
    .replace(/\{/, ``)
    .replaceAll(/\s\"\$/g, `(block $`)
    .replaceAll(/\}/g, `)`)
    .replaceAll(/\"|\:|\{|\,/g, ``)
    .replaceAll(/\s\)/g, `)`)
    .replace(/\)\)/, `)`)
    .replaceAll(/\n(\s+)\(block(.*)\)/g, `\n$1(block$2\n\n$1)`)
    .replaceAll(/\n(\s+)\(block/g, `\n\n$1(block`)
    .replaceAll(/\(block\s+\$(.*)\.(.[^\.]*)\/(set|get)(\s+)\n(\s+)\)/gm, `(block $$$1.$2/$3
$5    (local.set [LEVEL:$1.$2]
$5        (call $get 
$5            (call $desc (local.get [LEVEL:$1]) (text "$2"))
$5            (text "$3")
$5        )
$5    )
$5    (HAS_FUNCREF:$1.$2/$3)
$5    (HAS_EXTERNREF:$1.$2/$3)
$5    (HAS_GLOBAL:$1.$2/$3)
$5)`)
    .replaceAll(/\(block\s+\$(.*)\.(.[^\.]*)\/(value)(\s+)\n(\s+)\)/gm, `(block $$$1.$2
$5    (local.set [LEVEL:$1.$2]
$5        (call $get (local.get [LEVEL:$1]) (text "$2"))
$5    )
$5    (HAS_FUNCREF:$1.$2/$3)
$5    (HAS_EXTERNREF:$1.$2/$3)
$5    (HAS_GLOBAL:$1.$2/$3)
$5)`)
    .replaceAll(/\(block\s+\$(.*)\.(.[^\.]*)\/(value)(\s+)\n(\s+)/gm, `(block $$$1.$2
$5(local.set [LEVEL:$1.$2]
$5    (call $get (local.get [LEVEL:$1]) (text "$2"))
$5)
$5(HAS_FUNCREF:$1.$2/$3)
$5(HAS_EXTERNREF:$1.$2/$3)
$5(HAS_GLOBAL:$1.$2/$3)

$5`)
;



Object.keys(tables["ref.extern"]).forEach(v => {
    blocks_wat = blocks_wat.replace(`(HAS_EXTERNREF:${v})`, `[EXTERNREF:${v}]`)
})

Object.keys(tables["ref.func"]).forEach(v => {
    blocks_wat = blocks_wat.replace(`(HAS_FUNCREF:${v})`, `{FUNCREF:${v}}`)
})

Object.keys(tables["ref.global"]).forEach(v => {
    blocks_wat = blocks_wat.replace(`(HAS_GLOBAL:${v})`, `(GLOBAL:${v})`)
})

Object.keys(tables["call_direct"]).forEach(v => {
    blocks_wat = blocks_wat.replace(`(HAS_FUNCREF:${v})`, `[FUNCREF:${v}]`)
})

blocks_wat = blocks_wat
    .replace(/\n\s+\(HAS\_(.[^\)]*)\)/g, ``)
    .replace(/\/value/g, ``)
    ;


Array.from(blocks_wat.matchAll(/\[LEVEL\:(.*)\]/g)).forEach(m => {
    blocks_wat = blocks_wat.replaceAll(m[0], m[1].split(".").length)
});

let imports_wat = ``;
let import_index = 0;
let funcref_count = 0;
let externref_count = 0;
let funcref_elements = ``;
let externref_elements = ``;
let max_level = 1;

blocks_wat.matchAll(/\n(\s+)\[FUNCREF\:(.*)\]/g).forEach((m,i) => {
    const $name = m[2];
    const level = $name.split(".").length;
    max_level = Math.max(level, max_level);
    const func_index = funcref_count++;
    const setter = `

${m[1]}(call $set (local.get $funcref) (i32.const ${func_index}) (local.get ${level}))`;

    blocks_wat = blocks_wat.replaceAll(m[0], setter);
    imports_wat = imports_wat.concat(`
    (import "0" "${func_index}" (func (param) (result))) (; ${$name} ;)`
    );

    funcref_elements = funcref_elements.concat(`
        (ref.func ${func_index})`);
});

imports_wat = imports_wat.concat("\n")

blocks_wat.matchAll(/\n(\s+)\[EXTERNREF\:(.*)\]/g).forEach((m,i) => {
    const $name = m[2];
    const level = $name.split(".").length;
    max_level = Math.max(level, max_level);

    const extern_index = externref_count++;

    const setter = `

${m[1]}(call $set (local.get $externref) (i32.const ${extern_index}) (local.get ${level}))`;

    blocks_wat = blocks_wat.replaceAll(m[0], setter);
    imports_wat = imports_wat.concat(`
    (import "1" "${extern_index}" (global externref)) (; ${$name} ;)`);
    
    externref_elements = externref_elements.concat(`
        (global.get ${extern_index})`);
});


imports_wat = String(`
(module
    ${imports_wat.trimStart()}
    
    (memory (export "memory") 1 65536 shared)
    
    (elem funcref 
        ${funcref_elements.trimStart()}
    )
    
    (elem externref 
        ${externref_elements.trimStart()}
    )
        
    (func $init
        (table.init 0 0 (i32.const 0) (i32.const 0) (i32.const ${funcref_count}))
        (table.init 1 1 (i32.const 0) (i32.const 0) (i32.const ${externref_count}))

        (elem.drop 0)
        (elem.drop 1)

        (i32.store (i32.const 0) (i32.const 16))
    )

    (table (export "funcref") ${funcref_count} 65536 funcref)
    (table (export "externref") ${externref_count} 65536 externref)

    (start $init)
)
`).trim();

;

fs.writeFileSync("/tmp/interset.wat", imports_wat)
cp.execSync(`wat2wasm /tmp/interset.wat --enable-threads -o /tmp/interset.wasm`)
const wasm = fs.readFileSync("/tmp/interset.wasm", "hex").replaceAll(/(..)/g, `\\$1`);
fs.unlinkSync("/tmp/interset.wasm")

blocks_wat = blocks_wat.split("\n").join("\n      ")

const locals = new Array(max_level+1).fill(`externref`).join(` `);

const wat4 = `
(module
    (import "self" "self" (global $self externref))
    (import "self" "Array" (func $array (param) (result externref)))
    (import "Reflect" "get" (func $get (param externref externref) (result externref)))
    (import "Reflect" "set" (func $get (param externref i32 externref) (result)))
    (import "Reflect" "apply" (func $apply (param externref externref externref) (result externref)))
    (import "Reflect" "getOwnPropertyDescriptor" (func $desc (param externref externref) (result externref)))

    (memory 1)

    (func $main
        (local ${locals})
        (local $funcref externref)
        (local $externref externref)
        (local $imports externref)

        (local.set $funcref     (call $array))
        (local.set $externref   (call $array))
        (local.set $imports     (call $array))

        (call $set (local.get $imports) (i32.const 0) (local.get $funcref))
        (call $set (local.get $imports) (i32.const 1) (local.get $externref))

        |-------------------------------------------------------------------
        |                                                                  |
        |       (blocks ...)' || blocks_wat.trimStart()}                   |
        |                                                                  |
        |       (call $apply                                               |
        |           (local.get $WebAssembly.instantiate)                   |
        |           (data.view $export.wasm)                               |
        |           (local.get $imports)                                   |
        |       )                                                          |
        |       (then $onwasmready                                         |
        |           (param $instance   <Object>)                           |
        |           (result           <Promise>)                           |
        |                                                                  |
        |           (call $apply                                           |
        |               (local.get $WebAssembly.instantiate)               |
        |               (data.view $module.wasm)                           |
        |               (call $get (local.get 0) (text "exports"))         |
        |           )                                                      |
        |       )                                                          |
        |       (then $onmoduleready                                       |
        |           (param $instance   <Object>)                           |
        |                                                                  |
        |           (;                                                     |
        |               at                                                 |
        |                  this                                            |
        |                       point                                      |
        |                  done                                             |
        |               is                                               |
        |           ;)                                                     |
        |       )                                                          |
        |                                                                  |
        |------------------------------------------------------------------|
    )

    (data $module "\\00\\00\\00\\00")
    (data $export "${wasm}")

    (start $main)
)`; 

fs.writeFileSync("interset.wat", imports_wat)


console.log(wat4);
