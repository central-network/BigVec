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
let text_length = ``;
let interset_wat = ``;
let text_count = 0;
let funcref_count = 1;
let externref_count = 1;
let ref_count = 1;
let funcref_elements = `(ref.func 0)`;
let externref_elements = `(global.get 0)`;
let textref_elements = ``;
let max_level = 1;

let func_interset_wat = `(import "0" "0" (func (; void ;) (param) (result)))`;
let ref_interset_wat = `(import "1" "0" (global (; null ;) externref))`;
let text_interset_wat = ``;


String.prototype.encode = function () {
    const buffer = [];

    for (const char of this) {
        const code = char.codePointAt(0); // Emojiyi tek parça sayı olarak alır (örn: 128640)

        if (code < 128) {
            // ASCII: Direkt ekle (1 Bayt)
            buffer.push(code);
        } else {
            // UNICODE: İşaretçi (255) + 4 Bayt (Little Endian)
            buffer.push(128); 
            buffer.push(code & 0xff);
            buffer.push((code >> 8) & 0xff);
            buffer.push((code >> 16) & 0xff);
            buffer.push((code >> 24) & 0xff);
        }
    }

    return buffer;
}

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
$5        (call $eget 
$5            (local.get [LEVEL:$1]) 
$5            (text "$2")
$5        )
$5    )
$5    (HAS_FUNCREF:$1.$2/$3)
$5    (HAS_EXTERNREF:$1.$2/$3)
$5    (HAS_GLOBAL:$1.$2/$3)
$5)`)
    .replaceAll(/\(block\s+\$(.*)\.(.[^\.]*)\/(value)(\s+)\n(\s+)/gm, `(block $$$1.$2
$5(local.set [LEVEL:$1.$2]
$5    (call $eget 
$5        (local.get [LEVEL:$1]) 
$5        (text "$2")
$5    )
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
    blocks_wat = blocks_wat.replaceAll(m[0], m[1].split(".").length-1)
});

let bounds_wat = ``;

blocks_wat.matchAll(/\n(\s+)\[FUNCREF\:(.*)\]/g).forEach((m,i) => {    
    const fullpath = m[2];
    const signature = signatures.get(fullpath) || `(param) (result)`; 
    const level = fullpath.split(".").length-1;
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
    const level = fullpath.split(".").length-1;
    max_level = Math.max(level, max_level);

    const ref_index = ref_count++;
    const extern_index = externref_count++;
    matches.find(m => m.fullpath === fullpath).extern_index = extern_index;

    const setter = (`

${m[1]}(call $eset 
${m[1]}    (global.get $externref) 
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
        content = `(table.get $externref (i32.const ${m.extern_index})) (; "${m.fullpath}" ;)`
        blocks_wat = blocks_wat.replaceAll(
            m.block, `(table.get $externref (i32.const ${m.extern_index})) (; "${m.fullpath}" ;)`
        )
    }
    else
    if (tag === "text") 
    {
        content = `(table.get $textref (i32.const ${m.text_index})) (; "${m.fullpath}" ;)`
    }

    wat2 = before.concat(content).concat(after);
});


const text_block_matches = Array.from(
    wat2.concat(blocks_wat).concat(`
        (text "bind")    
        (text "call")    
        (text "WebAssembly")    
        (text "instantiate")    
        (text "compile")    
        (text "exports")    
        (text "Uint8Array")    
        (text "construct")    
        (text "Reflect")    
        (text "Promise")    
        (text "prototype")    
        (text "instance")    
        (text "then")    
        (text "wasm")    
    `).matchAll(/\((text|string|char)\s+\"(.[^\"]*)\"\)/gm)
);

const text_block_contents = new Map();
const text_block_offsets = new Map();
let text_blocks_buffer = new Array();

text_block_matches.sort((a, b) => b[2].length - a[2].length)
text_block_matches.map(m => {

    m.block = m.input.blockAt(m.index);
    m.text = m[2];
    
    const encodedTextBuffer = m.text.encode();

    m.offset = text_blocks_buffer.findIndex((v,i,t) => {
        encodedTextBuffer.every((e,j) => t.at(i+j) === e)
    });    

    if (-1 === m.offset) {
        m.offset = text_blocks_buffer.length;
        m.length = encodedTextBuffer.length;

        text_blocks_buffer.push.apply(text_blocks_buffer, encodedTextBuffer)
        
        m.extern_index = externref_count++;
        m.text_index = text_count++;

        m.preview = m.text.substring(0, 17).concat( m.length > 17 && ".." || "" );

        text_interset_wat = text_interset_wat.concat(`
    (import "2" "${m.text_index}" (global (; "${m.preview}" ;) externref))`);
    
    textref_elements = textref_elements.concat(` (global.get ${m.extern_index})`);

    text_block = `
        (block $decode/${m.text_index} (; $texts[${m.text_index}] = "${m.preview}" ;)
            (local.set $point_idx   (i32.const 0))
            (local.set $cursor      (i32.const 0)) 
            (local.set $end         (i32.const ${m.length})) 
            (local.set $length      (i32.const 0)) 

            (loop $codePointAt
                (if (i32.lt_u (local.get $length) (local.get $end))
                    (then
                        (local.set $cursor (i32.add (local.get $length) (i32.const ${m.offset})))
                        (local.set $code_point (i32.load8_u (local.get $cursor)))

                        (if (i32.eq (local.get $code_point) (i32.const 128))
                            (then                            
                                (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                            )
                        )

                        (local.set $length (i32.add (local.get $length) (i32.const 1)))

                        (call $iset 
                            (local.get $args) 
                            (local.get $point_idx) 
                            (local.get $code_point)
                        )

                        (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                        (br $codePointAt)
                    ) 
                )
            )

            (call $eset 
                (global.get $texts) 
                (i32.const ${m.text_index}) 
                (call $apply (global.get $strf) (ref.null extern) (local.get $args))
            )
        )

        ${text_block}
        `
        
        text_block_offsets.set(m.offset, m)
        matches.push(m)
    }
    
    text_block_contents.set(m.block, m.offset)
});

text_block_contents.forEach((text_data_offset) => {
    const m = text_block_offsets.get(text_data_offset);

    wat2 = wat2.replaceAll(
        m.block, `(table.get $textref (i32.const ${m.text_index})) (; "${m.preview}" ;)`
    );

    blocks_wat = blocks_wat.replaceAll(
        m.block, String(`(call $iget (global.get $texts) (i32.const ${m.text_index}))`)
    );
});


blocks_wat = blocks_wat.replace(`(block $self`, `(block $self
    (local.set 0 (global.get $self))`)


interset_wat = String(`
(module
    ${func_interset_wat.trimStart()}
    ${ref_interset_wat.trimStart()}
    ${text_interset_wat.trimStart()}
    
    (table (;0;) (export "funcref") ${funcref_count} 65536 funcref)
    (table (;1;) (export "externref") ${ref_count} 65536 externref)
    (table (;2;) (export "textref") ${text_count} 65536 externref)

    (elem (table 0) (i32.const 0) funcref ${funcref_elements.trim()})
    (elem (table 1) (i32.const 0) externref ${externref_elements.trim()})
    (elem (table 2) (i32.const 0) externref ${textref_elements.trim()})
)
`).trim();

fs.writeFileSync("/tmp/interset.wat", interset_wat)
cp.execSync(`wat2wasm /tmp/interset.wat --enable-threads --debug-names -o /tmp/interset.wasm`)
cp.execSync(`wat2wasm /tmp/interset.wat --enable-threads --debug-names `)
const interset_wasm = fs.readFileSync("/tmp/interset.wasm", "hex").replaceAll(/(..)/g, `\\$1`);
fs.unlinkSync("/tmp/interset.wasm")
fs.writeFileSync("interset.wat", interset_wat)

blocks_wat = blocks_wat.replace(/\/value/g, ``);
blocks_wat = blocks_wat.split("\n").join("\n      ")


const imports_begin = wat2.indexOf("(module") + ("(module".length) + 1; 
wat2 = String(`(module
    (import "wasm" "funcref" (table $funcref ${funcref_count} 65536 funcref))
    (import "wasm" "externref" (table $externref ${ref_count} 65536 externref))
    (import "wasm" "textref" (table $textref ${text_count} 65536 externref))
\n`).concat(wat2.substring(imports_begin))
    .replaceAll("(self)", `(table.get $externref (i32.const 0))`)
    .replaceAll("(null)", `(ref.null extern)`)
    .replaceAll("(void)", `(ref.null func)`)
    .replaceAll("(this)", `(local.get 0)`)
    .replaceAll(/\(start\s+(\$.[^\s]*)(\s*)\)/gm, `(smask $1$2)`)
    .replaceAll(/\(start\s+(\$.[^\s]*)/gm, `(start $1)\n\n\t(func $1\n`)
    .replaceAll(`(smask `, `(start`)
    ;

fs.writeFileSync("directed.wat", wat2)

fs.writeFileSync("/tmp/directed.wat", wat2)
cp.execSync(`wat2wasm /tmp/directed.wat --enable-threads --debug-names -o /tmp/directed.wasm`)
cp.execSync(`wat2wasm /tmp/directed.wat --enable-threads `)
const directed_wasm = fs.readFileSync("/tmp/directed.wasm", "hex").replaceAll(/(..)/g, `\\$1`);
fs.unlinkSync("/tmp/directed.wasm")


const find_text_index = str => text_block_offsets.get(text_block_contents.get(`(text "${str}")`)).text_index;
const $call_iget_text = str => `(call $iget (global.get $texts) (i32.const ${find_text_index(str)}))`;

const locals = new Array(max_level+1).fill(`externref`).join(` `);

const wat4 = `
(module
    (import "self" "self"                           (global $self externref))
    (import "String" "fromCodePoint"                (global $strf externref))
    (import "Reflect" "getOwnPropertyDescriptor"    (func $desc (param externref externref) (result externref)))
    (import "Reflect" "get"                         (func $eget (param externref externref) (result externref)))
    (import "Reflect" "get"                         (func $iget (param externref i32) (result externref)))
    (import "Reflect" "set"                         (func $tset (param externref externref externref)))
    (import "Reflect" "set"                         (func $eset (param externref i32 externref)))
    (import "Reflect" "set"                         (func $fset (param externref i32 funcref)))
    (import "Reflect" "set"                         (func $iset (param externref i32 i32)))
    (import "Reflect" "apply"                       (func $apply (param externref externref externref) (result externref)))
    (import "self" "Array"                          (func $array (result externref)))
    (import "console" "log"                          (func $log (param externref)))

    (global $texts (mut externref) (ref.null extern))
    (global $externref (mut externref) (ref.null extern))

    (memory 1)

    (func $main
        (local ${locals})
        (local $funcref      externref)
        (local $imports      externref)
        (local $args         externref)
        (local $cursor       i32)
        (local $length       i32)
        (local $end          i32)
        (local $point_idx    i32)
        (local $func_idx     i32)
        (local $code_point   i32)
        (local $temp         externref)
        (local $interset.wasm externref)
        (local $directed.wasm externref)

        (block $create_local_variables
            (local.set $funcref     (call $array))
            (global.set $externref  (call $array))
            (local.set $imports     (call $array))
            (global.set $texts      (call $array))

            (call $eset (local.get $imports) (i32.const 0) (local.get $funcref))
            (call $eset (local.get $imports) (i32.const 1) (global.get $externref))
            (call $eset (local.get $imports) (i32.const 2) (global.get $texts))

            (call $fset (local.get $funcref)   (i32.const 0) (ref.null func))
            (call $eset (global.get $externref) (i32.const 0) (global.get $self))
        )

        (block $decode_string_literals
            (local.set $args (call $array))
            
            ${text_block.trim()}

            (memory.fill (i32.const 0) (i32.const 0) (i32.const ${text_blocks_buffer.length}))
            (data.drop $text)
        )

        (block $settle_externref_items
            (local.set $args (call $array))
            
            ${blocks_wat.trim()}
        )

        (block $caller_bound_functions
        
            (br_if $caller_bound_functions 
                (i32.const ${funcref_count})
                (i32.eqz (local.tee $func_idx))
            )

            (local.set $args (call $array))

            (local.set 0
                (call $eget
                    (global.get $strf)
                    ${$call_iget_text('bind')}
                )
            )

            (local.set 1
                (call $eget 
                    (global.get $strf)
                    ${$call_iget_text('call')}
                )
            )

            (loop $binding
                (local.set $func_idx (i32.sub (local.get $func_idx) (i32.const 1)))

                (call $eset 
                    (local.get $args) 
                    (i32.const 0) 
                    (call $iget (local.get $funcref) (local.get $func_idx))
                )
                
                (call $eset 
                    (local.get $funcref) 
                    (local.get $func_idx)
                    (call $apply
                        (local.get 0) 
                        (local.get 1) 
                        (local.get $args)
                    )
                )

                (br_if $binding (local.get $func_idx))
            )
        )

        (block $cloning_wasm_source
            (local.set $args (call $array))

            (local.set 0 ${$call_iget_text('Reflect')})
            (local.set 0 (call $eget (global.get $self) (local.get 0)))

            (local.set 1 ${$call_iget_text('construct')})
            (local.set 1 (call $eget (local.get 0) (local.get 1)))

            (local.set 2 ${$call_iget_text('Uint8Array')})
            (local.set 2 (call $eget (global.get $self) (local.get 2)))
            
            (call $eset (local.get $args) (i32.const 0) (local.get 2) )

            (local.set $cursor (i32.const ${interset_wasm.length/3}))
            (memory.init $interset_wasm (i32.const 0) (i32.const 0) (local.get $cursor))
            (data.drop $interset_wasm)

            (call $eset (local.get $args) (i32.const 1) (local.tee 3 (call $array)))
            (call $iset (local.get 3) (i32.const 0) (local.get $cursor))
            
            (local.set 4 (call $apply (local.get 1) (local.get 0) (local.get $args)))

            (loop $bufferize 
                (if (local.tee $cursor (i32.sub (local.get $cursor) (i32.const 1)))
                    (then
                        (call $iset
                            (local.get 4)
                            (local.get $cursor)
                            (i32.load8_u (local.get $cursor))
                        )

                        (br $bufferize)
                    )
                )
            )

            (local.set $args (call $array))

            (call $eset 
                (local.get $args) 
                (i32.const 0) 
                (local.get 4)
            )

            (call $eset 
                (local.get $args) 
                (i32.const 1) 
                (local.get $imports)
            )
            
            (local.set 0 (call $eget (global.get $self) ${$call_iget_text('WebAssembly')}))
            (local.set 1 (call $eget (local.get 0) ${$call_iget_text('instantiate')}))

            (local.set 2 ${$call_iget_text('Promise')})
            (local.set 2 (call $eget (global.get $self) (local.get 2)))

            (local.set 3 (call $eget (local.get 2) ${$call_iget_text('prototype')}))
            (local.set 3 (call $eget (local.get 3) ${$call_iget_text('then')}))

            (call $fset
                (local.tee 4 (call $array))
                (i32.const 0) 
                (ref.func $oninstersetinstance)
            )
            
            (call $apply 
                (local.get 3)
                (call $apply (local.get 1) (ref.null extern) (local.get $args))
                (local.get 4)
            )

            (drop)
        )
    )

    (elem funcref (ref.func $oninstersetinstance) (ref.func $ondirectedinstance))

    (func $ondirectedinstance
        (param $exports externref)
        (local.get 0)
        (call $eget ${$call_iget_text('instance')})
        (call $log)
    )

    (func $oninstersetinstance
        (param $exports externref)
        (param $instantiate externref)
        (param $arguments externref)
        (param $Uint8Array externref)
        (param $construct externref)
        (param $arrayargs externref)
        (param $source externref)
        (param $then externref)
        (param $callbackargs externref)
        (param $cursor i32)

        (local.set $instantiate 
            (global.get $self) 
            (call $eget ${$call_iget_text('WebAssembly')})
            (call $eget ${$call_iget_text('instantiate')})
        )

        (local.set $construct 
            (global.get $self) 
            (call $eget ${$call_iget_text('Reflect')})
            (call $eget ${$call_iget_text('construct')})
        )

        (local.set $Uint8Array 
            (global.get $self) 
            (call $eget ${$call_iget_text('Uint8Array')})
        )

        (local.set $cursor   (i32.const ${directed_wasm.length/3}))
        (local.set $exports  (call $eget (local.get $exports) ${$call_iget_text('instance')}))
        (local.set $exports  (call $eget (local.get $exports) ${$call_iget_text('exports')}))

        (call $tset (global.get $self) ${$call_iget_text('wasm')} (local.get $exports))

        (memory.init $directed_wasm (i32.const 0) (i32.const 0) (local.get $cursor))
        (data.drop $directed_wasm)

        (local.set $arrayargs (call $array))
        (local.set $arguments (call $array))

        (call $iset (local.get $arrayargs) (i32.const 0) (local.get $cursor))
        (call $eset (local.get $arguments) (i32.const 0) (local.get $Uint8Array))
        (call $eset (local.get $arguments) (i32.const 1) (local.get $arrayargs))

        (local.set $source
            (call $apply
                (local.get $construct)
                (ref.null extern)
                (local.get $arguments)
            )
        )

        (loop $bufferize 
            (if (local.tee $cursor (i32.sub (local.get $cursor) (i32.const 1)))
                (then
                    (call $iset
                        (local.get $source)
                        (local.get $cursor)
                        (i32.load8_u (local.get $cursor))
                    )

                    (br $bufferize)
                )
            )
        )

        (local.set $then
            (global.get $self)
            (call $eget ${$call_iget_text('Promise')})
            (call $eget ${$call_iget_text('prototype')}) 
            (call $eget ${$call_iget_text('then')})
        )        

        (local.set $arguments (call $array))
        (call $eset (local.get $arguments) (i32.const 0) (local.get $source))
        (call $eset (local.get $arguments) (i32.const 1) (global.get $self))

        (local.set $instantiate
            (call $apply 
                (local.get $instantiate) 
                (ref.null extern) 
                (local.get $arguments)
            )
        )

        (call $fset 
            (local.tee $callbackargs (call $array))
            (i32.const 0) 
            (ref.func $ondirectedinstance)
        )

        (call $apply
            (local.get $then)
            (local.get $instantiate)
            (local.get $callbackargs)
        )

        (drop)        
    )

    (data $text (i32.const 0) "${Buffer.from( Uint8Array.from(text_blocks_buffer).buffer ).toString('hex').replaceAll(/(..)/g, `\\$1`)}")
    (data $interset_wasm "${interset_wasm}")
    (data $directed_wasm "${directed_wasm}")

    (start $main)
)`; 

let opener = 0;
let closer = 0;
let trimedLine, padding, padlen;
const _wat4 = wat4.split(/\n/).map(line => {
    if (trimedLine = line.trim()) {
        
        switch (trimedLine.at(0)) {
            case "(":
                padlen = 4 * (opener - closer);
                padding = ` `.repeat(padlen);
                line = padding.concat(trimedLine);
            break;

            case ")":
                padlen = 4 * (opener - closer - 1);
                padding = ` `.repeat(padlen);
                line = padding.concat(trimedLine);
            break;
        }

        opener += line.split("(").length;
        closer += line.split(")").length;
    }

    return line;
}).join("\n").replace(/\/value/g, ``);

fs.writeFileSync("manipulated.wat", _wat4)
fs.writeFileSync("/tmp/manipulated.wat", _wat4)
cp.execSync(`wat2wasm /tmp/manipulated.wat --enable-threads --debug-names`)
console.log(_wat4);