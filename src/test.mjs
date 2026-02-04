import fs from "fs"
import cp from "child_process"

let wat = fs.readFileSync("g.wat", "utf8");

const tables = {
    ["ref.func"] : {},
    ["ref.extern"] : {},
    ["call_direct"] : {},
    ["ref.global"] : {},
};

const matches = [];

const enclosers = (opener) => {
    switch (String(opener).at(0)) {
        case "(": return [ '(', ')' ];
        case "[": return [ '[', ']' ];
        case "<": return [ '<', '>' ];
        case "{": return [ '{', '}' ];
        case '"': return [ '"', '"' ];
        case "`": return [ '`', '`' ];
        case "'": return [ "'", "'" ];
    }
    
    return [];
}


const closerof = (opener) => {
    switch (opener.at(0)) {
        case "(": return ')';
        case "[": return ']';
        case "<": return '>';
        case "{": return '}';
        case '"': return '"';
        case "`": return '`';
        case "'": return "'";
    }    

    throw `No closer!`;
}

const walker = new Set();
const blocks = new Object();
const signatures = new Map();

let text_data = ``;
let interset_wat = ``;
let text_count = 0;
let funcref_count = 1;
let externref_count = 1;
let ref_count = 1;
let funcref_elements = `(ref.func 0)`;
let externref_elements = `(global.get 0)`;
let max_level = 1;

let func_interset_wat = `(import "0" "0" (func (; void ;) (param) (result)))`;
let ref_interset_wat = `(import "1" "0" (global (; null ;) externref))`;
let text_interset_wat = ``;


String.prototype.isBlock = function () {
    let raw = this.trim();
    switch (raw.at(0)) {
        case "(": return raw.endsWith(')');
        case "[": return raw.endsWith(']');
        case "<": return raw.endsWith('>');
        case "{": return raw.endsWith('}');
        case '"': return raw.endsWith('"');
        case "`": return raw.endsWith('`');
        case "'": return raw.endsWith("'");
    }
}


String.prototype.blockAt = function (begin = 0, opener = '(') {
    while (!this.at(begin))
        begin++;
    
    let raw = this.substring(begin);

    if (raw.isBlock()) {
        let closer = closerof(opener);
        let block, end = raw.indexOf(closer, 1);

        while (end !== -1) {
            block = raw.substring(0, ++end);
            
            if (block.split(opener).length === 
                block.split(closer).length) {
                return block;
            }

            end = raw.indexOf(closer, end);
        }
    }

    return "";
}


String.prototype.blockTag = function (begin = 0) {
    while (!this.at(begin))
        begin++;

    while (!this.at(begin).match(/[\w\d\.\_]/i))
        begin++;
    
    let end = 0,
        tag = ``,
        raw = this.substring(begin);

    while (raw.at(end).match(/[\w\d\.\_]/i))
        tag = tag + raw.at(end++);

    return tag;
}

class Signature extends Array {
    get param () { return this.filter(i => i.blockTag() === "param") }
    get result () { return this.filter(i => i.blockTag() === "param") }

    toString () { return this.join(" ") }

    static isType (str) { return str.blockTag() === "type"; }
    static isParam (str) { return str.blockTag() === "param"; }
    static isResult (str) { return str.blockTag() === "result"; }
    static isArgument (str) {
        return (
            this.isType(str) || 
            this.isParam(str) ||
            this.isResult(str)
        );
    }

    static unpack (type, raw) {
        const content = type.substring(1, type.length-1);
        const regexp = new RegExp(`\\(${content.replaceAll(/([^\w])/g, '\\$1').replaceAll(/\\\s+/g, '\\s+')}\\s+\\(func\\s*(.*)\\)\\)`, 'm');
        return Signature.from((raw.match(regexp)?.at(1) || '').match(/(\((?:param|result)(?:.*?)\))+/gm) || []);
    }
}

String.prototype.signature = function (raw = this) {
    const signature = new Signature;
    
    let begin = 0,  
        fullbody = this.blockAt(begin), match;

    if (fullbody = fullbody.substring(1, fullbody.length-1)) {
        let begin = fullbody.indexOf("("), block;

        while (begin !== -1) {
            block = fullbody.blockAt(begin++)
            
            if (Signature.isType(block)) {
                return Signature.unpack(block, raw) || block;
            }
            
            if (Signature.isArgument(block) === false) {
                return signature;
            }

            begin = fullbody.indexOf("(", begin);
            signature.push(block);
        }
    }

    return signature;
}

String.prototype.$name = function () {
    const parts = this.split(/\s(\$.*)/);
    if (parts.length < 2) return "";
    return parts.at(1).split(/\s|\(|\)/).at(0);
}

Array.from(wat.matchAll(/\((call_direct|ref\.(?:extern|func|global))\s+\$(.[^\s|\)]*)(\s+|\))/g)).forEach(m => {
    delete m.groups;
    delete m.input;

    m.block = wat.blockAt(m.index);
    m.$name = m.block.$name();
    m.fullpath = `self.${m[2]}`;

    m.fullpath = m.fullpath.replaceAll("self.self", "self");
    m.fullpath = m.fullpath.replaceAll(/\:(.)/g, `.prototype.$1`).replaceAll(/\:/g, `.prototype`)
    m.fullpath = m.fullpath.replaceAll(/([A-Z](?:.*)(?:8|16|32|64)(?:.*)Array)(\.prototype\.[a-z]+)/g, "Uint8Array.__proto__$2");
    m.fullpath = m.fullpath.concat(`/value`).replace(/\[(get|set|value)\]\/value/g, `/$1`);

    if (m[1] === "ref.func" && wat.match(new RegExp(`\\(func\\s+\\$${m[2]}[\\s|\\)]`, "gm"))) {
        return;
    }

    if (m[1] === "call_direct") {
        const begin = m.index;
        const block = wat.blockAt(begin);
        signatures.set(m.fullpath, block.signature(wat));
    }

    tables[m[1]][m.fullpath] ??= new Set();
    tables[m[1]][m.fullpath].add(m[0].trim());

    walker.add(m.fullpath);
    matches.push(m)
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
$5        (call $eget 
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
$5        (call $eget (local.get [LEVEL:$1]) (text "$2"))
$5    )
$5    (HAS_FUNCREF:$1.$2/$3)
$5    (HAS_EXTERNREF:$1.$2/$3)
$5    (HAS_GLOBAL:$1.$2/$3)
$5)`)
    .replaceAll(/\(block\s+\$(.*)\.(.[^\.]*)\/(value)(\s+)\n(\s+)/gm, `(block $$$1.$2
$5(local.set [LEVEL:$1.$2]
$5    (call $eget (local.get [LEVEL:$1]) (text "$2"))
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
    ;


Array.from(blocks_wat.matchAll(/\[LEVEL\:(.*)\]/g)).forEach(m => {
    blocks_wat = blocks_wat.replaceAll(m[0], m[1].split(".").length)
});

blocks_wat.matchAll(/\n(\s+)\[FUNCREF\:(.*)\]/g).forEach((m,i) => {    
    const fullpath = m[2];
    const signature = signatures.get(fullpath) || `(param) (result)`; 
    const level = fullpath.split(".").length;
    max_level = Math.max(level, max_level);

    const func_index = funcref_count++;
    matches.find(m => m.fullpath === fullpath).func_index = func_index;

    const setter = `

${m[1]}(call $eset 
${m[1]}    (local.get $funcref) 
${m[1]}    (i32.const ${func_index}) 
${m[1]}    (local.get ${level})
${m[1]})`;

    blocks_wat = blocks_wat.replaceAll(m[0], setter);
    func_interset_wat = func_interset_wat.concat(`
    (import "0" "${func_index}" (func (; ${fullpath} ;) ${signature}))`
    );

    funcref_elements = funcref_elements.concat(` (ref.func ${func_index})`).trim();
});


blocks_wat.matchAll(/\n(\s+)\[EXTERNREF\:(.*)\]/g).forEach((m,i) => {
    const fullpath = m[2];
    const level = fullpath.split(".").length;
    max_level = Math.max(level, max_level);

    const ref_index = ref_count++;
    const extern_index = externref_count++;
    matches.find(m => m.fullpath === fullpath).extern_index = extern_index;

    const setter = (`

${m[1]}(call $eset 
${m[1]}    (local.get $externref) 
${m[1]}    (i32.const ${ref_index}) 
${m[1]}    (local.get ${level})
${m[1]})`
);

    blocks_wat = blocks_wat.replaceAll(m[0], setter);
    ref_interset_wat = ref_interset_wat.concat(`
    (import "1" "${ref_index}" (global (; ${fullpath} ;) externref))`);
    
    externref_elements = externref_elements.concat(` (global.get ${extern_index})`);
});

let text_block = ``;

Array.from(wat.matchAll(/\((text|string|char)\s+\"(.[^\"]*)\"\)/gm)).forEach(m => {
    delete m.groups;
    delete m.input;

    m.block = wat.blockAt(m.index);
    m.text = m[2];

    m.offset = text_data.indexOf(m.text);
    m.length = m.text.length;

    if (-1 === m.offset) {
        m.offset = text_data.length;
        text_data = text_data + m.text;
        
        m.extern_index = externref_count++;
        m.text_index = text_count++;
        m.preview = m.text.substring(0, 17).concat( m.length > 17 && ".." || "" );

        text_interset_wat = text_interset_wat.concat(`
    (import "2" "${m.text_index}" (global (; "${m.preview}" ;) externref))`);
    
    externref_elements = externref_elements.concat(` (global.get ${m.extern_index})`);

    text_block = `
        ${text_block}

        (block (; "${m.preview}" ;)
            (local.set $arguments (call $array))
            (local.set $length (i32.const ${m.length}))
            (local.set $offset (i32.const ${m.offset}))

            (loop $charCodeAt
                (if (local.tee $length (i32.sub (local.get $length) (i32.const 1)))
                    (then
                        (call $iset 
                            (local.get $arguments)
                            (local.get $length)
                            (i32.load8_u (i32.add (i32.const ${m.offset}) (local.get $length)))
                        )

                        (br $charCodeAt)
                    )
                )
            )

            (call $eset 
                (local.get $texts) 
                (i32.const ${m.text_index}) 
                (call $apply 
                    (global.get $strf) 
                    (ref.null extern) 
                    (local.get $arguments)
                )
            )
        )`
    }

    matches.push(m)
});


Array.from(blocks_wat.matchAll(/\((text|string|char)\s+\"(.[^\"]*)\"\)/gm)).map(m => {
    delete m.groups;
    delete m.input;

    m.block = blocks_wat.blockAt(m.index);
    m.text = m[2];

    m.offset = text_data.indexOf(m.text);
    m.length = m.text.length;

    if (-1 === m.offset) {
        m.offset = text_data.length;
        text_data = text_data + m.text;
        
        m.extern_index = externref_count++;
        m.text_index = text_count++;
        m.preview = m.text.substring(0, 17).concat( m.length > 17 && ".." || "" );

        text_interset_wat = text_interset_wat.concat(`
    (import "2" "${m.text_index}" (global (; "${m.preview}" ;) externref))`);
    
    externref_elements = externref_elements.concat(` (global.get ${m.extern_index})`);

    text_block = `
        ${text_block}

        (block (; "${m.preview}" ;)
            (local.set $arguments (call $array))
            (local.set $length (i32.const ${m.length}))
            (local.set $offset (i32.const ${m.offset}))

            (loop $charCodeAt
                (if (local.tee $length (i32.sub (local.get $length) (i32.const 1)))
                    (then
                        (call $iset 
                            (local.get $arguments)
                            (local.get $length)
                            (i32.load8_u (i32.add (i32.const ${m.offset}) (local.get $length)))
                        )

                        (br $charCodeAt)
                    )
                )
            )

            (call $eset 
                (local.get $texts) 
                (i32.const ${m.text_index}) 
                (call $apply 
                    (global.get $strf) 
                    (ref.null extern) 
                    (local.get $arguments)
                )
            )
        )`;
    }
    return m;

}).filter(m => !isNaN(m.text_index)).forEach(m => {
    blocks_wat = blocks_wat.replaceAll(
        m.block, `(call $iget (local.get $texts) (i32.const ${m.text_index}))`
    )
});


interset_wat = String(`
(module
    ${func_interset_wat.trimStart()}
    ${ref_interset_wat.trimStart()}
    ${text_interset_wat.trimStart()}
    
    (table (;0;) (export "funcref") ${funcref_count} 65536 funcref)
    (table (;1;) (export "externref") ${externref_count} 65536 externref)

    (elem (table 0) (i32.const 0) funcref ${funcref_elements.trim()})
    (elem (table 1) (i32.const 0) externref ${externref_elements.trim()})
)
`).trim();

fs.writeFileSync("/tmp/interset.wat", interset_wat)
cp.execSync(`wat2wasm /tmp/interset.wat --enable-threads --enable-function-references -o /tmp/interset.wasm`)
cp.execSync(`wat2wasm /tmp/interset.wat --enable-threads --enable-function-references `)
const interset_wasm = fs.readFileSync("/tmp/interset.wasm", "hex").replaceAll(/(..)/g, `\\$1`);
fs.unlinkSync("/tmp/interset.wasm")
fs.writeFileSync("interset.wat", interset_wat)

blocks_wat = blocks_wat
    .replace(/\/value/g, ``)
    ;

blocks_wat = blocks_wat.split("\n").join("\n      ")

let wat2 = wat;

matches.sort((b,a) => a.index - b.index).forEach(m => {
    let content = wat2.blockAt(m.index);
    const tag = content.blockTag();
    const before = wat2.substring(0, m.index);
    const after = wat2.substring(m.index + content.length);

    content = content.substring(
        content.indexOf("(") + 1, 
        content.lastIndexOf(")")
    ).trim();

    if (tag === "call_direct")
    {
        content = content.replace('call_direct', "call_indirect")
        content = content.replace(m.$name, "$funcref")
        
        const lines = content.split(`\n`);
        const margin = m.index - before.lastIndexOf("\n", m.index);
        const padding = lines.filter(n => n.trim()).pop().match(/[^\s]/)?.index || 0;
        const indexLine = ' '.repeat(padding).concat(`(i32.const ${m.func_index})`);
    
        content = lines
            .concat(indexLine)
            .join("\n");

        content = String()
            .concat(`(`)
            .concat(content)
            .concat(`\n`)
            .concat(`)`.padStart(margin))
            .concat(`\n`)
            ;
    }
    else
    if (tag === "ref.extern") 
    {
        content = `(table.get $externref (i32.const ${m.extern_index}))`
    }
    else
    if (tag === "text") 
    {
        content = `(table.get $externref (i32.const ${m.extern_index}))`
    }

    wat2 = before.concat(content).concat(after);
});

const imports_begin = wat2.indexOf("(module") + ("(module".length) + 1; 
wat2 = String(`(module
    (import "0" "funcref" (table $funcref ${funcref_count} 65536 funcref))
    (import "0" "externref" (table $externref ${externref_count} 65536 externref))
\n`).concat(wat2.substring(imports_begin));

fs.writeFileSync("directed.wat", wat2)

fs.writeFileSync("/tmp/directed.wat", wat2)
cp.execSync(`wat2wasm /tmp/directed.wat --enable-threads -o /tmp/directed.wasm`)
cp.execSync(`wat2wasm /tmp/directed.wat --enable-threads `)
const directed_wasm = fs.readFileSync("/tmp/directed.wasm", "hex").replaceAll(/(..)/g, `\\$1`);
fs.unlinkSync("/tmp/directed.wasm")




const locals = new Array(max_level+1).fill(`externref`).join(` `);

const wat4 = `
(module
    (import "self" "self" (global $self externref))
    (import "self" "Array" (func $array (param) (result externref)))
    (import "Reflect" "get" (func $eget (param externref externref) (result externref)))
    (import "Reflect" "get" (func $iget (param externref i32) (result externref)))
    (import "Reflect" "set" (func $eset (param externref i32 externref) (result)))
    (import "Reflect" "set" (func $iset (param externref i32 i32) (result)))
    (import "Reflect" "set" (func $fset (param externref i32 funcref) (result)))
    (import "Reflect" "apply" (func $apply (param externref externref externref) (result externref)))
    (import "Reflect" "getOwnPropertyDescriptor" (func $desc (param externref externref) (result externref)))
    (import "String" "fromCharCode" (global $strf externref))

    (memory 1)

    (func $main
        (local ${locals})
        (local $funcref externref)
        (local $externref externref)
        (local $imports externref)
        (local $texts externref)
        (local $string externref)
        (local $arguments externref)
        (local $index i32)
        (local $offset i32)
        (local $length i32)

        (local.set $funcref     (call $array))
        (local.set $externref   (call $array))
        (local.set $imports     (call $array))
        (local.set $texts       (call $array))

        (call $eset (local.get $imports) (i32.const 0) (local.get $funcref))
        (call $eset (local.get $imports) (i32.const 1) (local.get $externref))
        (call $eset (local.get $imports) (i32.const 2) (local.get $texts))

        (call $fset (local.get $funcref) (i32.const 0) (ref.null func))
        (call $eset (local.get $externref) (i32.const 0) (ref.null extern))

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
        |               (call $eget (local.get 0) (text "exports"))         |
        |           )                                                      |
        |       )                                                          |
        |       (then $onmoduleready                                       |
        |           (param $instance   <Object>)                           |
        |                                                                  |
        |               at                                                 |
        |                  this                                            |
        |                       point                                      |
        |                  done                                            |
        |               is                                                 |
        |                                                                  |
        |           -> TRANSFERABLE_ITEMS: memory + text                   |
        |           -> ASSIGN_PER_PROCESS: extern + func                   |
        |       )                                                          |
        |                                                                  |
        |------------------------------------------------------------------|
        
        ${text_block}
        ${blocks_wat}
    )

    (data $str_charcodes (i32.const 0) "${Buffer.from(text_data).toString('hex').replaceAll(/(..)/g, `\\$1`)}")
    (data $directed_wasm "${directed_wasm}")
    (data $interset_wasm "${interset_wasm}")

    (start $main)
)`; 


console.log(wat4)
