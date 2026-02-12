import fs from "fs"
import cp from "child_process"

const tbl_externref = new Map();

tbl_externref.set("$null", tbl_externref.size)
tbl_externref.set("$self", tbl_externref.size)
tbl_externref.set("$self.Reflect.get", tbl_externref.size)
tbl_externref.set("$self.String.fromCharCode", tbl_externref.size)
const imported_extern_global_getters = [`(ref.null extern)`, ...Array.from(tbl_externref.keys()).slice(1).map((k,i) => `(global.get ${i})`)].join(` `);
const imported_extern_global_headers = [...tbl_externref.keys()].slice(1).map(k => `self.${k.substring(1)}`.split(".").slice(-2)).map(([root, prop],i, a) => `(import "${root}" "${prop}"`.padEnd(32, " ").concat(`(global externref))`)).join(`\n\t\t`);

tbl_externref.set("$self.Reflect.getOwnPropertyDescriptor", tbl_externref.size)
tbl_externref.set("$self.Reflect.construct", tbl_externref.size)
tbl_externref.set("$self.Function", tbl_externref.size)
tbl_externref.set("$self.Function.bind", tbl_externref.size)
tbl_externref.set("$self.Function.call", tbl_externref.size)
tbl_externref.set("$self.Uint8Array", tbl_externref.size)
tbl_externref.set("$self.WebAssembly.compile", tbl_externref.size)
tbl_externref.set("$self.WebAssembly.instantiate", tbl_externref.size)
tbl_externref.set("$self.WebAssembly.Instance:exports[get]", tbl_externref.size)
tbl_externref.set("$self.WebAssembly.Memory:buffer[get]", tbl_externref.size)
const imported_global_ref_extern = [...tbl_externref.keys()].slice(1).map(k => `(ref.extern ${k})`).join(`\n\t`);

const parse = path => {
    console.log("started for:", path)
    const raw = fs.readFileSync(path, "utf8");
    const exp = /\(include\s+\"(.[^\"]*)\"\s*\)/;

    let fullpath = import.meta.dirname.concat(`/${path}`),
        content = raw,
        m, dir = fullpath.substring(0, fullpath.lastIndexOf("/"))
        ;

    while (m = content.match(exp)) {
        fullpath = dir.concat(`/${m.at(1)}`);
        dir = fullpath.substring(0, fullpath.lastIndexOf("/"));

        content = content.replace(m.at(0),
            fs.readFileSync(fullpath, `utf8`)
        );
    };

    const self = imported_global_ref_extern.concat(content)
        ?.match(/\$self([a-z0-9\.\:\_])*(\[(get|set)\])*/ig)
        ?.map(m => m.replaceAll(/\:/g, `.prototype.`))
        ?.filter((m,i,t) => t.lastIndexOf(m) === i)
        ;

    const keys = self
        ?.flatMap(m => m.match(/([a-z0-9]+)/gi))
        ?.filter((m,i,t) => t.lastIndexOf(m) === i)
        ?.sort((a,b) => a.length - b.length)
        ;

    const walk = self
        .map(k => k.split("."))
        .flatMap(s => s.map((w,i,p) => p.slice(0,i).concat(w).join(".")))
        .filter((m,i,t) => m !== "$self" && t.slice(0, i).indexOf(m) === -1)
        ;

    let buffer = Buffer.alloc(4096 * 128); 
    const begin = 8;
    
    let dataOffset = begin;
    let padding;

    const OFFSET_KEYS_HEADER = dataOffset;
    const BEGIN_KEYS_LENGTH = 0;
    const BEGIN_KEYS_COUNT = 2;
    const BEGIN_KEYS_DATA = dataOffset += 4;
    
    const BEGIN_KEY_LENGTH = 0;
    const BEGIN_KEY_INDEX = 1;
    const BEGIN_KEY_DATA = 2;
    const LENGTH_KEY_HEADER = BEGIN_KEY_DATA;

    const get_keys_length   = () => buffer.readUint16LE(OFFSET_KEYS_HEADER + BEGIN_KEYS_LENGTH);
    const set_keys_length   = (value = 0) => buffer.writeUint16LE(value, OFFSET_KEYS_HEADER + BEGIN_KEYS_LENGTH);
    const add_keys_length   = (value = 1) => set_keys_length( get_keys_length() + value );

    const get_keys_count    = () => buffer.readUint16LE(OFFSET_KEYS_HEADER + BEGIN_KEYS_COUNT);
    const set_keys_count    = (value = 0) => buffer.writeUint16LE(value, OFFSET_KEYS_HEADER + BEGIN_KEYS_COUNT);
    const add_keys_count    = (value = 1) => set_keys_count( get_keys_count() + value );

    const get_key_length    = (offset) => buffer.readUint8(offset + BEGIN_KEY_LENGTH);
    const set_key_length    = (value, offset) => buffer.writeUint8(value, offset + BEGIN_KEY_LENGTH);
    const add_key_length    = (value, offset) => set_key_length(get_key_length(offset) + value, offset);

    const get_key_index     = (offset) => buffer.readUint8(offset + BEGIN_KEY_INDEX);
    const set_key_index     = (value, offset) => buffer.writeUint8(value, offset + BEGIN_KEY_INDEX);
    const set_key_data_at   = (value, index, offset) => buffer.writeUint8(value, index + offset + BEGIN_KEY_DATA);
    
    const set_key_value     = (value, offset) => {
        if (tbl_externref.get(value)) return;

        const data = [...value].map(c => c.charCodeAt());
        const index = tbl_externref.size;
        const length = data.length;

        set_key_index(index, offset);
        set_key_length(length, offset);
        
        data.forEach((v, i) => set_key_data_at(v, i, offset));
        
        add_keys_length(length);
        add_keys_count(1);

        tbl_externref.set(value, index);

        return offset + length + LENGTH_KEY_HEADER;
    }
        
    set_keys_length(0);
    set_keys_count(0);

    for (const key of keys) {
        dataOffset = set_key_value(key, dataOffset);
    }

    dataOffset += (4 - dataOffset % 4);

    const OFFSET_SELF_HEADER = dataOffset;
    const BEGIN_SELF_EXT_COUNT = 0;
    const BEGIN_SELF_FUN_COUNT = 4;
    const BEGIN_SELF_COUNT = 8;
    const BEGIN_SELF_DATA = dataOffset += 16;

    const get_self_ext_count   = () => buffer.readUint32LE(OFFSET_SELF_HEADER + BEGIN_SELF_EXT_COUNT);
    const set_self_ext_count   = (value = 0) => buffer.writeUint32LE(value, OFFSET_SELF_HEADER + BEGIN_SELF_EXT_COUNT);
    const add_self_ext_count   = (value = 1) => {
        const idx = get_self_ext_count();
        set_self_ext_count( idx + value );
        return idx;
    };

    const get_self_fun_count   = () => buffer.readUint32LE(OFFSET_SELF_HEADER + BEGIN_SELF_FUN_COUNT);
    const set_self_fun_count   = (value = 0) => buffer.writeUint32LE(value, OFFSET_SELF_HEADER + BEGIN_SELF_FUN_COUNT);
    const add_self_fun_count   = (value = 1) => {
        const idx = get_self_fun_count();
        set_self_fun_count( idx + value );
        return idx;
    };

    const get_self_count    = () => buffer.readUint32LE(OFFSET_SELF_HEADER + BEGIN_SELF_COUNT);
    const set_self_count    = (value = 0) => buffer.writeUint32LE(value, OFFSET_SELF_HEADER + BEGIN_SELF_COUNT);
    const add_self_count    = (value = 1) => set_self_count( get_self_count() + value );

    set_self_ext_count(2); //null, self
    set_self_fun_count(1);

    const BEGIN_EXTREF_FUNC_INDEX = 0;
    const BEGIN_EXTREF_THIS_INDEX = 2;
    const BEGIN_EXTREF_ARG0_INDEX = 4;
    const BEGIN_EXTREF_ARG1_INDEX = 6;
    const BEGIN_EXTREF_OUTPUT_IDX = 8;
    const BEGIN_EXTREF_IMPORT_EXT = 10;
    const BEGIN_EXTREF_IMPORT_FUN = 12;
    const BEGIN_EXTREF_RESERVED_2 = 14;
    const BYTES_PER_EXTERNREF_STEP = 16;

    const get_extref_func_index  = (offset) => buffer.readUint16LE(offset + BEGIN_EXTREF_FUNC_INDEX);
    const set_extref_func_index  = (value, offset) => buffer.writeUint16LE(value, offset + BEGIN_EXTREF_FUNC_INDEX);
    const set_extref_func_key    = (key, offset) => set_extref_func_index(tbl_externref.get(key), offset);
    const set_extref_func_$bind  = (offset) => set_extref_func_key("$self.Function.bind", offset);
    const set_extref_func_$rget  = (offset) => set_extref_func_key("$self.Reflect.get", offset);
    const set_extref_func_$desc  = (offset) => set_extref_func_key("$self.Reflect.getOwnPropertyDescriptor", offset);

    const get_extref_this_index  = (offset) => buffer.readUint16LE(offset + BEGIN_EXTREF_THIS_INDEX);
    const set_extref_this_index  = (value, offset) => buffer.writeUint16LE(value, offset + BEGIN_EXTREF_THIS_INDEX);
    const set_extref_this_key    = (key, offset) => set_extref_this_index(tbl_externref.get(key), offset);
    const set_extref_this_$call  = (offset) => set_extref_this_key("$self.Function.call", offset);
    const set_extref_this_null   = (offset) => set_extref_this_key("$null", offset);

    const get_extref_arg0_index  = (offset) => buffer.readUint16LE(offset + BEGIN_EXTREF_ARG0_INDEX);
    const set_extref_arg0_index  = (value, offset) => buffer.writeUint16LE(value, offset + BEGIN_EXTREF_ARG0_INDEX);
    const set_extref_arg0_key    = (key, offset) => set_extref_arg0_index( tbl_externref.get(key), offset );
    const set_extref_arg0_$self  = (offset) => set_extref_arg0_key( "$self", offset );

    const get_extref_arg1_index  = (offset) => buffer.readUint16LE(offset + BEGIN_EXTREF_ARG1_INDEX);
    const set_extref_arg1_index  = (value, offset) => buffer.writeUint16LE(value, offset + BEGIN_EXTREF_ARG1_INDEX);
    const set_extref_arg1_key    = (key, offset) => set_extref_arg1_index( tbl_externref.get(key), offset );
    const set_extref_arg1_null   = (offset) => set_extref_arg1_key( "$null", offset );

    const get_extref_output_idx  = (offset) => buffer.readUint16LE(offset + BEGIN_EXTREF_OUTPUT_IDX);
    const set_extref_output_idx  = (value, offset) => buffer.writeUint16LE(value, offset + BEGIN_EXTREF_OUTPUT_IDX);
    const add_extref_output_idx  = (key, offset) => {
        let index;

        if (tbl_externref.has(key)) {
            index = tbl_externref.get(key);
        } else {
            index = tbl_externref.size; 
            tbl_externref.set(key, index);
        }

        set_extref_output_idx(index, offset);
        return index;
    };

    const get_extref_import_ext  = (offset) => buffer.readUint16LE(offset + BEGIN_EXTREF_IMPORT_EXT);
    const set_extref_import_ext  = (value, offset) => buffer.writeUint16LE(value, offset + BEGIN_EXTREF_IMPORT_EXT);

    const get_extref_import_fun  = (offset) => buffer.readUint16LE(offset + BEGIN_EXTREF_IMPORT_FUN);
    const set_extref_import_fun  = (value, offset) => buffer.writeUint16LE(value, offset + BEGIN_EXTREF_IMPORT_FUN);


    dataOffset = BEGIN_SELF_DATA;
    
    for (const fullpath of walk) {

        let parts = fullpath.split(".");
        let [key, dkey] = parts.pop().match(/(.[^\[]*)(?:\[(get|set|value)\]*)*/).slice(1);
        let parent = parts.join(".");
        let parent_i = tbl_externref.get(parent);


        if (dkey) {
            parent = parent.concat(`.ownPropertyDescriptor["${key}"]`);
 
            set_extref_func_$desc(dataOffset);
            set_extref_this_null(dataOffset);
            set_extref_arg0_index(parent_i, dataOffset);
            set_extref_arg1_key(key, dataOffset);
            add_extref_output_idx(parent, dataOffset);

            add_self_count();
            
            key = dkey;
            parent_i = get_extref_output_idx(dataOffset);
            dataOffset += BYTES_PER_EXTERNREF_STEP;
        }

        set_extref_func_$rget(dataOffset);
        set_extref_this_null(dataOffset);
        set_extref_arg0_index(parent_i, dataOffset);
        set_extref_arg1_key(key, dataOffset);
        add_extref_output_idx(fullpath, dataOffset);
        add_self_count();
        
        const offset = dataOffset;
        dataOffset += BYTES_PER_EXTERNREF_STEP;
        
        if (self.includes(fullpath)) {
            const masked = fullpath.replace(/([^a-z0-9])/ig, '\\$1');
            const regexp = new RegExp(`\\((.*)\\s+${masked}(?:\\s+|\\))`, "g");
            const fcontt = content.replaceAll(/\:/g, `.prototype.`);
            const matchs = Array.from(fcontt.matchAll(regexp)).map(m => m.pop());

            for(const type of matchs) {
                const tpath = fullpath.concat(".", type);
                switch (type) {
                    case "ref.extern": 
                        set_extref_import_ext(add_self_ext_count(1), offset);
                    break;
                }
            }
        }

        if (self.includes(fullpath)) {
            const masked = fullpath.replace(/([^a-z0-9])/ig, '\\$1');
            const regexp = new RegExp(`\\((.*)\\s+${masked}(?:\\s+|\\))`, "g");
            const fcontt = content.replaceAll(/\:/g, `.prototype.`);
            const matchs = Array.from(fcontt.matchAll(regexp)).map(m => m.pop());

            for(const type of matchs) {
                const tpath = fullpath.concat(".", type);
                switch (type) {
                    case "call":
                    case "call_direct":
                        set_extref_func_$bind(dataOffset);
                        set_extref_this_$call(dataOffset);
                        set_extref_arg0_index(parent_i, dataOffset);
                        set_extref_arg1_null(dataOffset);
                        set_extref_import_fun(add_self_fun_count(1), dataOffset);
                        add_extref_output_idx(tpath, dataOffset);
                        
                        dataOffset += BYTES_PER_EXTERNREF_STEP;
                        add_self_count();
                    break;
                }
            }
        }
    }

    tbl_externref.set("$deeper_apply_func", tbl_externref.size);
    tbl_externref.set("$deeper_apply_this", tbl_externref.size);
    tbl_externref.set("$deeper_apply_argv", tbl_externref.size);
    tbl_externref.set("$deeper_apply_argv_arg0", tbl_externref.size);
    tbl_externref.set("$deeper_apply_argv_arg1", tbl_externref.size);
    tbl_externref.set("$deeper_apply_out", tbl_externref.size);
    
    tbl_externref.set("$apply_func", tbl_externref.size);
    tbl_externref.set("$apply_this", tbl_externref.size);
    tbl_externref.set("$apply_argv", tbl_externref.size);
    tbl_externref.set("$apply_argv_arg0", tbl_externref.size);
    tbl_externref.set("$apply_argv_arg0_deeper_out", tbl_externref.size);
    tbl_externref.set("$apply_argv_arg0_deeper_argv", tbl_externref.size);
    tbl_externref.set("$apply_argv_arg1", tbl_externref.size);
    tbl_externref.set("$apply_out", tbl_externref.size);

    dataOffset += (4 - dataOffset % 4);
    console.log(dataOffset)

    const BEGIN_TABLE_EXPORTER_WASM     = dataOffset;
    const CONTENT_TABLE_EXPORTER_WAT    = String(`(module
    ${Array(get_self_ext_count()).fill().map((k,i) => `
    (import "0" "${i}" (global externref))`).join(``).trim()}
    
    ${Array(get_self_fun_count()).fill().map((k,i) => `
    (import "1" "${i}" (func (param) (result)))`).join(``).trim()}
    
    (table (export "ext") ${get_self_ext_count()} 65536 externref)
    (table (export "fun") ${get_self_fun_count()} 65536 funcref)

    (elem (table 0) (i32.const 0) externref ${Array(get_self_ext_count()).fill().map((k,i) => `(global.get ${i})`).join(` `).trim()})
    (elem (table 1) (i32.const 0) funcref ${Array(get_self_fun_count()).fill().map((k,i) => `(ref.func ${i})`).join(` `).trim()})\n)`);

    const DATA_TABLE_EXPORTER_WASM      = [
        fs.writeFileSync("/tmp/table_exporter_wat", CONTENT_TABLE_EXPORTER_WAT),
        cp.execSync(`wat2wasm /tmp/table_exporter_wat --output /tmp/table_exporter_wat`),
        fs.readFileSync("/tmp/table_exporter_wat"), 
        fs.unlinkSync("/tmp/table_exporter_wat")
    ].at(2);
    const LENGTH_TABLE_EXPORTER_WASM    = DATA_TABLE_EXPORTER_WASM.byteLength;

    DATA_TABLE_EXPORTER_WASM.copy(buffer, dataOffset);

    dataOffset += LENGTH_TABLE_EXPORTER_WASM;

    console.log(CONTENT_TABLE_EXPORTER_WAT)
    console.log(DATA_TABLE_EXPORTER_WASM)


    const tbl_funcref = new Map();
    const tbl_signature = new Map();
    const tbl_funcref_path = new Map();

    tbl_funcref.set("$void0", tbl_funcref.size);
    tbl_funcref.set("$apply", tbl_funcref.size);
    tbl_funcref.set("$isete", tbl_funcref.size);
    tbl_funcref.set("$isetf", tbl_funcref.size);
    tbl_funcref.set("$iseti", tbl_funcref.size);
    tbl_funcref.set("$array", tbl_funcref.size);

    tbl_signature.set("$void0", "(param) (result)");
    tbl_signature.set("$apply", "(param externref externref externref) (result externref)");
    tbl_signature.set("$isete", "(param externref i32 externref) (result)");
    tbl_signature.set("$isetf", "(param externref i32 funcref) (result)");
    tbl_signature.set("$iseti", "(param externref i32 i32) (result)");
    tbl_signature.set("$array", "(param) (result externref)");

    tbl_funcref_path.set("$apply", [ "Reflect", "apply" ]);
    tbl_funcref_path.set("$isete", [ "Reflect", "set" ]);
    tbl_funcref_path.set("$isetf", [ "Reflect", "set" ]);
    tbl_funcref_path.set("$iseti", [ "Reflect", "set" ]);
    tbl_funcref_path.set("$array", [ "self", "Array" ]);

    let imported_func_global_headers = ``;
    let imported_func_global_getters = `(ref.null func)`; 

    tbl_funcref.forEach((index, $name) => {
        if (!index) { return };

        imported_func_global_headers = imported_func_global_headers
        .concat(`
        (import "${tbl_funcref_path.get($name).join('" "')}"`.padEnd(41, " "))
        .concat(`(func ${$name} ${tbl_signature.get($name)}))`);

        imported_func_global_getters = `
        ${imported_func_global_getters}
        (ref.func ${$name})
        `;
    })

    buffer = buffer.subarray(0, dataOffset);

    const data = buffer.toString('hex').replaceAll(/(..)/g, `\\$1`);
    const size = Math.ceil(buffer.byteLength / 65536); 

    const code = `
    (module
        ${imported_extern_global_headers}
        ${imported_func_global_headers}

        (import "console" "log"         (func $loge (param externref)))
        (import "console" "warn"        (func $warne (param externref)))
        (import "console" "warn"        (func $warni (param i32)))
        (import "console" "error"       (func $logi (param i32)))

        (memory ${size})

        (func $keys
            (local $keys_length i32)
            (local $keys_count  i32)
            (local $keys_index  i32)
            
            (local $key_length  i32)
            (local $key_index   i32)

            (local $data_index  i32)
            (local $data_value  i32)
            
            (local $i           i32)
            (local $ptr*        i32)
            (local $key_string  externref)
            (local $apply_args  externref)

            (local.set $apply_args  (call $array))
            (local.set $keys_length (i32.load16_u offset=${BEGIN_KEYS_LENGTH} (i32.const ${OFFSET_KEYS_HEADER})))
            (local.set $keys_count  (i32.load16_u offset=${BEGIN_KEYS_COUNT} (i32.const ${OFFSET_KEYS_HEADER})))
            (local.set $ptr*        (i32.const ${BEGIN_KEYS_DATA}))

            (loop $keys
                (local.set $key_length  (i32.load8_u offset=${BEGIN_KEY_LENGTH} (local.get $ptr*)))                
                (local.set $key_index   (i32.load8_u offset=${BEGIN_KEY_INDEX} (local.get $ptr*)))                
                (local.set $data_index  (i32.const 0))

                (loop $at
                    (local.set $data_value (i32.load8_u offset=${BEGIN_KEY_DATA} (local.get $ptr*)))                
                    (call $iseti (local.get $apply_args) (local.get $data_index) (local.get $data_value))
                    (local.set $ptr* (i32.add (i32.const 1) (local.get $ptr*))) 
                    (local.set $data_index (i32.add (i32.const 1) (local.get $data_index))) 
                    (br_if $at (i32.lt_u (local.get $data_index) (local.get $key_length)))
                )

                (local.set $ptr* (i32.add (i32.const ${LENGTH_KEY_HEADER}) (local.get $ptr*))) 
                (local.set $keys_index (i32.add (i32.const 1) (local.get $keys_index)))  
                (local.set $key_string 
                    (call $apply 
                        (table.get $self (i32.const ${tbl_externref.get("$self.String.fromCharCode")})) 
                        (table.get $self (i32.const ${tbl_externref.get("$null")})) 
                        (local.get $apply_args)
                    )
                )

                (table.set $self 
                    (local.get $key_index) 
                    (local.get $key_string)
                )

                (br_if $keys (i32.lt_u (local.get $keys_index) (local.get $keys_count)))
            )
        )

        (func $apply_extref 
            (param $func        i32)
            (param $this        i32)
            (param $arg0        i32)
            (param $arg1        i32)
            (result       externref)
            (local $args  externref)
            
            (local.set $args (call $array))

            (call $isete (local.get $args) (i32.const 0) (table.get $self (local.get $arg0)))
            (call $isete (local.get $args) (i32.const 1) (table.get $self (local.get $arg1)))

            (call_indirect $wasm 
                ${tbl_signature.get("$apply")}

                (table.get $self (local.get $func)) 
                (table.get $self (local.get $this)) 
                (local.get $args)

                (i32.const ${tbl_funcref.get("$apply")})
            )
        )

        (global $imports (mut externref) (ref.null extern))

        (func $pathwalk
            (local $count       i32)
            (local $i           i32)
            (local $ptr*        i32)
            (local $ext#  externref)
            
            (local $func        i32)
            (local $this        i32)
            (local $arg0        i32)
            (local $arg1        i32)

            (local $output_idx  i32)
            (local $import_ext  i32)
            (local $import_fun  i32)
            (local $reserved_2  i32)

            (local $imports_ext externref)
            (local $imports_fun externref)

            (local.set $count   (i32.load offset=${OFFSET_SELF_HEADER} (i32.const ${BEGIN_SELF_COUNT})))
            (local.set $ptr*    (i32.const ${BEGIN_SELF_DATA}))
            
            (global.set $imports (call $array))

            (call $isete (global.get $imports) (i32.const 0) (local.tee $imports_ext (call $array)))
            (call $isete (global.get $imports) (i32.const 1) (local.tee $imports_fun (call $array)))

            (loop $at
                (local.set $func (i32.load16_u offset=${BEGIN_EXTREF_FUNC_INDEX} (local.get $ptr*)))
                (local.set $this (i32.load16_u offset=${BEGIN_EXTREF_THIS_INDEX} (local.get $ptr*)))
                (local.set $arg0 (i32.load16_u offset=${BEGIN_EXTREF_ARG0_INDEX} (local.get $ptr*)))
                (local.set $arg1 (i32.load16_u offset=${BEGIN_EXTREF_ARG1_INDEX} (local.get $ptr*)))

                (local.set $output_idx (i32.load16_u offset=${BEGIN_EXTREF_OUTPUT_IDX} (local.get $ptr*)))
                (local.set $reserved_2 (i32.load16_u offset=${BEGIN_EXTREF_RESERVED_2} (local.get $ptr*)))

                (if (ref.is_null 
                        (local.tee $ext# (table.get $self (local.get $output_idx)))
                    )
                    (then
                        (local.set $ext# 
                            (call $apply_extref 
                                (local.get $func) 
                                (local.get $this) 
                                (local.get $arg0) 
                                (local.get $arg1)
                            )
                        )
                    )
                )
                (table.set $self (local.get $output_idx) (local.get $ext#))
                
                (local.tee $import_ext (i32.load16_u offset=${BEGIN_EXTREF_IMPORT_EXT} (local.get $ptr*)))
                (if (then (call $isete (local.get $imports_ext) (local.get $import_ext) (local.get $ext#))))
                
                (local.tee $import_fun (i32.load16_u offset=${BEGIN_EXTREF_IMPORT_FUN} (local.get $ptr*)))
                (if (then (call $isete (local.get $imports_fun) (local.get $import_fun) (local.get $ext#))))

                (local.set $i       (i32.add    (i32.const 1) (local.get $i))) 
                (local.set $ptr*    (i32.add    (local.get $ptr*) (i32.const ${BYTES_PER_EXTERNREF_STEP})))
                (br_if $at          (i32.lt_u   (local.get $i) (local.get $count)))
            )

            (call $isete (local.get $imports_ext) (i32.const 0) (table.get $self (i32.const ${tbl_externref.get("$null")})))
            (call $isete (local.get $imports_ext) (i32.const 1) (table.get $self (i32.const ${tbl_externref.get("$self")})))
            (call $isete (local.get $imports_fun) (i32.const 0) (table.get $self (i32.const ${tbl_externref.get("$self.Function")})))
        )

        (global $argv_level_0 (mut externref) (ref.null extern))
        (global $argv_level_1 (mut externref) (ref.null extern))

        (func $argv_builder_iseti
            (param $offset i32)
        )

        (func $instantiate
            (param $source      externref)
            (param $imports     externref)
            (result             externref)
            (local $argv        externref)

            (call_indirect $wasm
                ${tbl_signature.get("$array")}
                (i32.const ${tbl_funcref.get("$array")})
            )
            (local.set $argv)

            (call_indirect $wasm
                ${tbl_signature.get("$isete")}
                
                (local.get $argv) 
                (i32.const 0) 
                (local.get 0)

                (i32.const ${tbl_funcref.get("$isete")})
            )

            (call_indirect $wasm
                ${tbl_signature.get("$isete")}
                
                (local.get $argv) 
                (i32.const 1) 
                (local.get 1)

                (i32.const ${tbl_funcref.get("$isete")})
            )

            (call_indirect $wasm
                ${tbl_signature.get("$apply")}

                (table.get $self (i32.const ${tbl_externref.get("$self.WebAssembly.instantiate")}))
                (table.get $self (i32.const ${tbl_externref.get("$null")}))
                (local.get $argv)
                
                (i32.const ${tbl_funcref.get("$apply")})
            )
        )

        (func $buffers
            (local $byteOffset                    i32)
            (local $byteLength                    i32)
            (local $offsetByte                    i32)
            (local $bufferView              externref)
            (local $buffer                  externref)
            (local $apply_argv              externref)
            (local $construct_argv          externref)
            (local $self.Uint8Array         externref)
            (local $self.Reflect.construct  externref)

            (local.set $byteOffset (i32.const ${BEGIN_TABLE_EXPORTER_WASM}))
            (local.set $byteLength (i32.const ${LENGTH_TABLE_EXPORTER_WASM}))

            (local.set $apply_argv (call $array))
            (local.set $construct_argv (call $array))
            (local.set $self.Uint8Array (table.get $self (i32.const ${tbl_externref.get("$self.Uint8Array")})))
            (local.set $self.Reflect.construct (table.get $self (i32.const ${tbl_externref.get("$self.Reflect.construct")})))

            (call $iseti (local.get $apply_argv) (i32.const 0) (local.get $byteLength))
            (call $isete (local.get $construct_argv) (i32.const 0) (local.get $self.Uint8Array))
            (call $isete (local.get $construct_argv) (i32.const 1) (local.get $apply_argv))

            (local.set $bufferView
                (call $apply
                    (local.get $self.Reflect.construct)
                    (ref.null extern)
                    (local.get $construct_argv)
                )
            )

            (loop $read
                (local.tee $byteLength (i32.sub (local.get $byteLength) (i32.const 1)))
                (local.set $offsetByte (i32.load8_u (i32.add (local.get $byteOffset))))

                (call_indirect $wasm
                    ${tbl_signature.get("$iseti")} 

                    (local.get $bufferView)
                    (local.get $byteLength) 
                    (local.get $offsetByte) 
                    
                    (i32.const ${tbl_funcref.get("$iseti")})
                )
                    
                (br_if $read (local.get $byteLength))
            )

            (call $warne (global.get $imports))
            (call $warne (local.get $bufferView))
            (call $warne 
                (call $instantiate
                    (local.get $bufferView)
                    (global.get $imports)
                )
            )
        )

        (func $main#
            (call $keys)
            (call $pathwalk)
            (call $buffers)
        )

        (func $func_4
            (call $logi (call $**))
            (call $## (i32.const 22))
        )

        (func $func_5
            (call $warni (call $**))
        )

        (func $+- loop i32.const 0 i32.const 16 i32.atomic.rmw.add i32.load 
        (call_indirect) i32.const 4 i32.const 1 i32.atomic.rmw.sub br_if 0 end)        
        
        (func $** (result i32) (i32.load (i32.const 12)))
        (func $## (param i32) (i32.store (i32.const 12) (local.get 0)))

        (start $+-)

        
        (table $wasm ${tbl_funcref.size} funcref)
        (table $self ${tbl_externref.size} externref)

        (elem (table $self) (i32.const 0) externref ${imported_extern_global_getters})
        (elem (table $wasm) (i32.const 0) funcref ${imported_func_global_getters})
        
        (data (i32.const 0) "${data}")
        
        (elem (table $wasm) (i32.const 4) funcref (ref.func $func_4) (ref.func $func_5))

        (data (i32.const  0) "\\10\\00\\00\\00\\01\\00\\00\\00\\1b\\00\\00\\00\\1a\\00\\00\\00")
        (data (i32.const 16) "\\04\\00\\00\\00\\02\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00")
        (data (i32.const 32) "\\05\\00\\00\\00\\03\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00")
    )
    `;


    fs.writeFileSync("/tmp/wasm.wat", code)
    fs.writeFileSync("out.wat", code);
    cp.execSync(`wat2wasm /tmp/wasm.wat --enable-threads --debug-names --enable-function-references --output /tmp/code.wasm`);
    fs.writeFileSync("out.wasm", fs.readFileSync("/tmp/code.wasm"));
    
    fs.unlinkSync("/tmp/wasm.wat");
    fs.unlinkSync("/tmp/code.wasm");
};


parse(process.argv[2])
