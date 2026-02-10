import fs from "fs"
import cp from "child_process"

console.log("started for:", process.argv.slice(2))

String.prototype.encoder = TextEncoder.prototype.encode.bind(new TextEncoder)

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

String.prototype.blockHeadersAt = function (begin = 0) {
    return Array.from(this.blockSignatureAt(begin)).concat(
        Array.from(this.matchAll(/\(local\s/g)
        ).map(m => this.blockAt(m.index)).filter(Boolean)
    );
}


String.dataBuffer = Buffer.alloc(4);

String.prototype.dataOffset = function () {
    const data = Buffer.from(this);
    const length = data.byteLength;
    
    let offset = String.dataBuffer.indexOf(data);

    if (offset === -1) {
        offset = String.dataBuffer.byteLength;
        String.dataBuffer = Buffer.concat([
            String.dataBuffer, Buffer.alloc(1), data
        ]);

        String.dataBuffer.writeUint8(length, offset++);
        String.dataBuffer.writeUint32LE(offset + length, 0);
    }

    return offset;
};

String.prototype.dataLength = function () {
    const offset = String.dataBuffer.indexOf(Buffer.from(this));
    if (offset === -1) return 0;
    return String.dataBuffer.readUint8(offset-1);
};

String.prototype.toStringBlock = function () {
    const offset = this.dataOffset();
    const length = this.dataLength();

    return `
    (block $${this}:${offset}
        (local.set $point_at (i32.load8_u (i32.const ${offset-1}))) 
        (loop $--length (br_if $--length 
            (local.tee $point_at (i32.sub (local.get $point_at) (i32.const 1)))
            (local.set $value_i3 (i32.load8_u offset=${offset} (local.get $point_at)))
            (call $iset (local.get $args) (local.get $point_at) (local.get $value_i3))
        ))
        (call $eset (global.get $keys) (i32.const ${offset})
        (call $apply (global.get $strf) (ref.null extern) (local.get $args)))
    )
    `;
};


String.prototype.textReferences = function () {
    return Array.from(
        this.matchAll(/\(ref\.extern/g)
    ).map(m => this.blockAt(m.index)).filter(
        b => b.substring(b.indexOf(" ")).trim().at(0).match(/([\"|\'|\,])/)
    );
}

String.prototype.selfReferences = function () {
    return Array.from(
        this.matchAll(/(\s\$self)/g)
    ).map(m => 
        this.blockAt(this.substring(0, m.index).lastIndexOf("("))
    );
}

String.prototype.funcReferences = function () {
    return Array.from(
        this.matchAll(/\(ref\.func/g)
    ).map(m => this.blockAt(m.index));
}

String.prototype.blockSignatureAt = function (begin = 0) {
    const signature = new Signature;
    
    let fullbody = this.blockAt(begin), match;

    if (fullbody = fullbody.substring(1, fullbody.length-1)) {
        let begin = fullbody.indexOf("("), block;

        while (begin !== -1) {
            block = fullbody.blockAt(begin++)
            
            if (Signature.isType(block)) {
                return Signature.unpack(block, this) || block;
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

String.prototype.blockContentAt = function (begin = 0) {
    let fullbody = this.blockAt(begin);
    const tag = fullbody.blockTag();
    
    const bodyStart = Math.max(
        fullbody.indexOf("(param"),
        fullbody.indexOf("(result"),
        fullbody.indexOf("(local"),
    );

    if (bodyStart !== -1) {
        return fullbody.substring(
            fullbody.indexOf(")", bodyStart) + 1,
            fullbody.lastIndexOf(")")
        ).trim();
    }

    while (fullbody.at(0).match(/[\w|\.|\(|\)|\s]/)) {
        fullbody = fullbody.substring(1);
    }

    if (fullbody.at(0) === "$") {
        fullbody = fullbody.substring(1);
        while (!fullbody.at(0)?.match(/[\w|\.|\(|\)|\s]/)) {
            fullbody = fullbody.substring(1);
        }
        fullbody = fullbody.trim();
    }

    while (fullbody.at(-1)?.match(/[\w|\.|\(|\)|\s]/)) {
        fullbody = fullbody.substring(0, fullbody.length-1);
    }

    return fullbody;
}

String.prototype.$name = function () {
    const parts = this.split(/\s(\$.*)/);
    if (parts.length < 2) return "";
    return parts.at(1).split(/\s|\(|\)/).at(0);
}

String.prototype.hash = function (md5 = true) {
    if (md5 !== true) {
        return Array.from(this.encode()).map((c,i) => c * (i+1)).reduce((a,b) => a + b, 0) + this.length;
    }

    var r = 0,
        a = this,
        c = "";
    
    function h(t) {
        return u(l(m(t)))
    }

    function l(t) {
        return p(g(f(t), 8 * t.length))
    }

    function u(t) {
        for (var e, i = r ? "0123456789ABCDEF" : "0123456789abcdef", n = "", o = 0; o < t.length; o++)
            e = t.charCodeAt(o),
            n += i.charAt(e >>> 4 & 15) + i.charAt(15 & e);
        return n
    }

    function m(t) {
        for (var e, i, n = "", o = -1; ++o < t.length;)
            e = t.charCodeAt(o),
            i = o + 1 < t.length ? t.charCodeAt(o + 1) : 0,
            55296 <= e && e <= 56319 && 56320 <= i && i <= 57343 && (e = 65536 + ((1023 & e) << 10) + (1023 & i),
                o++),
            e <= 127 ? n += String.fromCharCode(e) : e <= 2047 ? n += String.fromCharCode(192 | e >>> 6 & 31, 128 | 63 & e) : e <= 65535 ? n += String.fromCharCode(224 | e >>> 12 & 15, 128 | e >>> 6 & 63, 128 | 63 & e) : e <= 2097151 && (n += String.fromCharCode(240 | e >>> 18 & 7, 128 | e >>> 12 & 63, 128 | e >>> 6 & 63, 128 | 63 & e));
        return n
    }

    function f(t) {
        for (var e = Array(t.length >> 2), i = 0; i < e.length; i++)
            e[i] = 0;
        for (i = 0; i < 8 * t.length; i += 8)
            e[i >> 5] |= (255 & t.charCodeAt(i / 8)) << i % 32;
        return e
    }

    function p(t) {
        for (var e = "", i = 0; i < 32 * t.length; i += 8)
            e += String.fromCharCode(t[i >> 5] >>> i % 32 & 255);
        return e
    }

    function g(t, e) {
        t[e >> 5] |= 128 << e % 32,
            t[14 + (e + 64 >>> 9 << 4)] = e;
        for (var i = 1732584193, n = -271733879, o = -1732584194, s = 271733878, a = 0; a < t.length; a += 16) {
            var r = i,
                c = n,
                h = o,
                l = s;
            n = E(n = E(n = E(n = E(n = N(n = N(n = N(n = N(n = C(n = C(n = C(n = C(n = S(n = S(n = S(n = S(n, o = S(o, s = S(s, i = S(i, n, o, s, t[a + 0], 7, -680876936), n, o, t[a + 1], 12, -389564586), i, n, t[a + 2], 17, 606105819), s, i, t[a + 3], 22, -1044525330), o = S(o, s = S(s, i = S(i, n, o, s, t[a + 4], 7, -176418897), n, o, t[a + 5], 12, 1200080426), i, n, t[a + 6], 17, -1473231341), s, i, t[a + 7], 22, -45705983), o = S(o, s = S(s, i = S(i, n, o, s, t[a + 8], 7, 1770035416), n, o, t[a + 9], 12, -1958414417), i, n, t[a + 10], 17, -42063), s, i, t[a + 11], 22, -1990404162), o = S(o, s = S(s, i = S(i, n, o, s, t[a + 12], 7, 1804603682), n, o, t[a + 13], 12, -40341101), i, n, t[a + 14], 17, -1502002290), s, i, t[a + 15], 22, 1236535329), o = C(o, s = C(s, i = C(i, n, o, s, t[a + 1], 5, -165796510), n, o, t[a + 6], 9, -1069501632), i, n, t[a + 11], 14, 643717713), s, i, t[a + 0], 20, -373897302), o = C(o, s = C(s, i = C(i, n, o, s, t[a + 5], 5, -701558691), n, o, t[a + 10], 9, 38016083), i, n, t[a + 15], 14, -660478335), s, i, t[a + 4], 20, -405537848), o = C(o, s = C(s, i = C(i, n, o, s, t[a + 9], 5, 568446438), n, o, t[a + 14], 9, -1019803690), i, n, t[a + 3], 14, -187363961), s, i, t[a + 8], 20, 1163531501), o = C(o, s = C(s, i = C(i, n, o, s, t[a + 13], 5, -1444681467), n, o, t[a + 2], 9, -51403784), i, n, t[a + 7], 14, 1735328473), s, i, t[a + 12], 20, -1926607734), o = N(o, s = N(s, i = N(i, n, o, s, t[a + 5], 4, -378558), n, o, t[a + 8], 11, -2022574463), i, n, t[a + 11], 16, 1839030562), s, i, t[a + 14], 23, -35309556), o = N(o, s = N(s, i = N(i, n, o, s, t[a + 1], 4, -1530992060), n, o, t[a + 4], 11, 1272893353), i, n, t[a + 7], 16, -155497632), s, i, t[a + 10], 23, -1094730640), o = N(o, s = N(s, i = N(i, n, o, s, t[a + 13], 4, 681279174), n, o, t[a + 0], 11, -358537222), i, n, t[a + 3], 16, -722521979), s, i, t[a + 6], 23, 76029189), o = N(o, s = N(s, i = N(i, n, o, s, t[a + 9], 4, -640364487), n, o, t[a + 12], 11, -421815835), i, n, t[a + 15], 16, 530742520), s, i, t[a + 2], 23, -995338651), o = E(o, s = E(s, i = E(i, n, o, s, t[a + 0], 6, -198630844), n, o, t[a + 7], 10, 1126891415), i, n, t[a + 14], 15, -1416354905), s, i, t[a + 5], 21, -57434055), o = E(o, s = E(s, i = E(i, n, o, s, t[a + 12], 6, 1700485571), n, o, t[a + 3], 10, -1894986606), i, n, t[a + 10], 15, -1051523), s, i, t[a + 1], 21, -2054922799), o = E(o, s = E(s, i = E(i, n, o, s, t[a + 8], 6, 1873313359), n, o, t[a + 15], 10, -30611744), i, n, t[a + 6], 15, -1560198380), s, i, t[a + 13], 21, 1309151649), o = E(o, s = E(s, i = E(i, n, o, s, t[a + 4], 6, -145523070), n, o, t[a + 11], 10, -1120210379), i, n, t[a + 2], 15, 718787259), s, i, t[a + 9], 21, -343485551),
                i = v(i, r),
                n = v(n, c),
                o = v(o, h),
                s = v(s, l)
        }
        return [i, n, o, s]
    }

    function _(t, e, i, n, o, s) {
        return v((a = v(v(e, t), v(n, s))) << (r = o) | a >>> 32 - r, i);
        var a, r
    }

    function S(t, e, i, n, o, s, a) {
        return _(e & i | ~e & n, t, e, o, s, a)
    }

    function C(t, e, i, n, o, s, a) {
        return _(e & n | i & ~n, t, e, o, s, a)
    }

    function N(t, e, i, n, o, s, a) {
        return _(e ^ i ^ n, t, e, o, s, a)
    }

    function E(t, e, i, n, o, s, a) {
        return _(i ^ (e | ~n), t, e, o, s, a)
    }

    function v(t, e) {
        var i = (65535 & t) + (65535 & e);
        return (t >> 16) + (e >> 16) + (i >> 16) << 16 | 65535 & i
    }

    return h(a);
};

String.prototype.replaceIncludes = function (directory = '') {
    let content = this;
    let m, regexp = /\(include\s+\"(.[^\"]*)\"\s*\)/;

    while (m = content.match(regexp)) {
        const [match, file] = m;
        const fullpath = directory.concat(`/${file}`).replaceAll("//", "/");
        const body = fs.readFileSync(fullpath, `utf8`);
        const filedir = fullpath.split("/").reverse().slice(1).reverse().join("/");
        content = content.replace(match, body.replaceIncludes(filedir));
    }

    return content;
} 

String.prototype.lastBuild = function (content) {
    const hash = this.hash(false);
    const file = `/tmp/${hash}.wasm`;

    if (content) {
        fs.writeFileSync(file, content);
        return content;
    }
    
    if (fs.existsSync(file)) {
        return fs.readFileSync(file);
    }
};

String.prototype.generatePathWalk = function () {
    let path = "",
        step = [],
        accessorType = "value";

    path = String("self.").concat(
        this.substring(this.indexOf("$") + 1)
    );

    path = path.replaceAll("self.self", "self");
    path = path.replaceAll(/\:(.)/g, `.prototype.$1`).replaceAll(/\:/g, `.prototype`)
    path = path.replaceAll(/([A-Z](?:.*)(?:8|16|32|64)(?:.*)Array)(\.prototype\.[a-z]+)/g, "Uint8Array.__proto__$2");

    if (path.endsWith("]")) {
        accessorType = path.substring(
            path.lastIndexOf("[") + 1,
            path.lastIndexOf("]")
        );

        path = path.substring(
            0, 
            path.length - 
            accessorType.length - 2
        );
    }

    step = path.split(".");

    return step.flatMap((key) => {
        return key.toStringBlock();
    });

    return step.map((key, lvl, t) => {
        if (lvl === 0) return "";
        
        const is_accessor_step = (key === t.at(-1)) && (accessorType !== "value"); 
        const parent_way = step.slice(1, lvl).join(".");
        const prop_way = step.slice(1, lvl).concat(key).join(".").concat(is_accessor_step && `/${accessorType}` || ``);
        const prop_way_id = prop_way.hash(0);
        const parent_way_id = parent_way.hash(0);

            return `
        (block $self.${prop_way}:${prop_way_id}
            (local.set $parent      (call $egete (local.get $props) (i32.const ${parent_way_id})))
            (local.set $name        (call $igete (local.get $keys) (i32.const ${key.dataOffset()})))
            ${String(is_accessor_step && `
            (local.set $descs       (call $descs (local.get $parent) (local.get $name)))
            (local.set $key         (call $igete (local.get $keys) (i32.const ${accessorType.dataOffset()})))
            (local.set $accessor    (call $egete (local.get $descs) (local.get $key)))
            (local.set $argv        (call $array (local.get $accessor)))
            (local.set $value       (call $apply (local.get $bind) (local.get $call) (local.get $argv)))
            ` || `
            (local.set $value       (call $egete (local.get $parent) (local.get $name)))
            `).trim()}
            (call $isete (local.get $props) (i32.const ${prop_way_id}) (local.get $value))
        )
        `
    })

    //return { path, prop, desc, step };
    return levels;
    


    const generateLevelBlock = (key, level, steps) => `
    (block $self.${steps.slice(1, level).concat(key).join(".")}
        (local.set $parent (local.get ${level-1}))
        (local.set $name_index (i32.const INDEX[${key}]))
        (local.set $key (call $iget (local.get $keys) (local.get $name_index)))
        (local.set $prop (call $eget (local.get $parent) (local.get $key)))
        (local.tee ${level} (local.get $prop))
        (call $iset (local.get $props) (local.get $at) (local.get $prop))
    )`;

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



const manipulateWAT = function (process_argv, meta_dirname) {
    const arg_process = process_argv.find(a => a.endsWith(".wat"));
    const wat_fullpath = meta_dirname.concat(`/${arg_process}`).replaceAll("//", "/");
    const wat_filename = wat_fullpath.split("/").pop();
    const wat_basename = wat_filename.substring(0, wat_filename.lastIndexOf("."));
    const wat_directory = wat_fullpath.substring(0, wat_fullpath.lastIndexOf(wat_filename));
    const wat_hash = wat_fullpath.hash();
    const wat_filetime = fs.statSync(wat_fullpath).mtimeMs.toString();
    const wat_content = fs.readFileSync(wat_fullpath, "utf8").replaceIncludes(wat_directory);
    const wasm_fullpath = wat_directory.concat(`${wat_basename}.wasm`);
    
    let wat = wat_content;
    
    let module_name = wat.match(/\(module\s+(\$.[^\s]*)/)?.pop() || "";
    const functions = Array.from(wat.matchAll(/\(func\s+(\$.[^\s|\)]*)/g)).map(f => Object({
        name: f.at(1),
        code: f.input.blockAt(f.index),
        sign: f.input.blockSignatureAt(f.index),
        head: f.input.blockHeadersAt(f.index),
        body: f.input.blockContentAt(f.index),
    })).map(b => Object.assign(b, {
        hash: b.code.hash(),
    })).map(f => Object.assign(f, {
        text: f.body.textReferences(),
        self: f.body.selfReferences(),
        func: f.body.funcReferences(),
    })).sort((a,b) => b.name.length - a.name.length);
    
    const output = {
        self : 1
    };

    const externs = "$" + functions.flatMap(f => 
        f.self
            .flatMap(s => s.match(/\$self(.*)/g))
            .map($self => $self.split(/\)/).at())
            .map($self => $self.substring(6).replace("[get]", ":1").replace("[set]", ":2"))
            .map($self => $self.concat(":0").replace(":1:0", ":1").replace(":2:0", ":2"))
    ).join("$") + "#";

    process.exit(console.log(externs));

    console.log(
        functions
            .flatMap(f => f.self.flatMap(r => r.generatePathWalk()) )
            .sort((a,b) => a.length - b.length)
            .filter((b,i,a) => a.lastIndexOf(b) === i)
            .join("")
    )
    console.log([String.dataBuffer.toString("utf8")])

    wat = wat
        .replaceAll("(self)", `(table.get $externref (i32.const 0))`)
        .replaceAll("(null)", `(ref.null extern)`)
        .replaceAll("(void)", `(ref.null func)`)
        .replaceAll("(this)", `(local.get 0)`)
        .replaceAll(/\(ref\.extern\s+\"/g, `(text "$1`)
        .replaceAll(/\(call\s+\$self\.(.[^\s]*)/g, `(call_direct $$$1`)
        .replaceAll(/(\s+)\(func\s+start\s+(\$.[^\s]*)/gm, `$1(start $2)$1(func $2`)
        .replaceAll(/\(module\s+(\$.[^\s]*)/gm, `(module `)
        ;
    
    const sub_modules = Array.from(wat.matchAll(/\(wasm\s+(\$.[^\s]*)\s+\"(.[^\"]*)\"\s*\)/g)).map(m => {
        delete m.input;
        delete m.groups;
    
        m.name = m[1];
        m.file = m[2];
        m.hash = m.file.hash();
    
        return m;
    });
    


    sub_modules.forEach(m => wat = wat.replace(m[0], `(; ${m.hash} ;)`));
    
    const tables = {
        ["ref.func"] : {},
        ["ref.extern"] : {},
        ["call_direct"] : {},
        ["ref.global"] : {},
    };
    
    const matches = [];
    
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
            signatures.set(m.fullpath, wat.blockSignatureAt(begin));
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
    let directed_wat = wat;
    
    matches.sort((b,a) => a.index - b.index).forEach(m => {
        let content = directed_wat.blockAt(m.index);
        const tag = content.blockTag();
        const before = directed_wat.substring(0, m.index);
        const after = directed_wat.substring(m.index + content.length);
    
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
    
        directed_wat = before.concat(content).concat(after);
    });
    
    
    const text_block_matches = Array.from(
        directed_wat.concat(blocks_wat).concat(`
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
    
        directed_wat = directed_wat.replaceAll(
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
    
    blocks_wat = blocks_wat.replace(/\/value/g, ``);
    blocks_wat = blocks_wat.split("\n").join("\n      ")
    
    
    const imports_begin = directed_wat.indexOf("(module") + ("(module".length) + 1; 
    directed_wat = String(`(module
        (import "wasm" "funcref" (table $funcref ${funcref_count} 65536 funcref))
        (import "wasm" "externref" (table $externref ${ref_count} 65536 externref))
        (import "wasm" "textref" (table $textref ${text_count} 65536 externref))
    \n`).concat(directed_wat.substring(imports_begin));
    
    
    fs.writeFileSync("/tmp/directed.wat", directed_wat)
    cp.execSync(`wat2wasm /tmp/directed.wat --enable-threads --debug-names -o /tmp/directed.wasm`)
    const directed_wasm = fs.readFileSync("/tmp/directed.wasm", "hex").replaceAll(/(..)/g, `\\$1`);
    
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
    let manipulated_wat = wat4.split(/\n/).map(line => {
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
    
    fs.writeFileSync("/tmp/manipulated.wat", manipulated_wat)
    cp.execSync(`wat2wasm /tmp/manipulated.wat --enable-threads --debug-names --output /tmp/manipulated.wasm`);
    const wasm = fs.readFileSync(`/tmp/manipulated.wasm`);
    
    fs.unlinkSync(`/tmp/manipulated.wasm`);
    fs.unlinkSync(`/tmp/manipulated.wat`);
    fs.unlinkSync("/tmp/directed.wasm");
    fs.unlinkSync("/tmp/directed.wat");
    fs.unlinkSync("/tmp/interset.wasm");
    fs.unlinkSync("/tmp/interset.wat");
    
    fs.writeFileSync("interset.wat", interset_wat);
    fs.writeFileSync("directed.wat", directed_wat);
    fs.writeFileSync("manipulated.wat", manipulated_wat);
    
    return wat_content.lastBuild(wasm);
}

manipulateWAT(process.argv, import.meta.dirname);