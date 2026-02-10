import fs from "fs"
import cp from "child_process"

const replaceIncludes = function (content, directory = import.meta.dirname) {
    let m, regexp = /\(include\s+\"(.[^\"]*)\"\s*\)/;

    while (m = content.match(regexp)) {
        const [match, file] = m;
        const fullpath = directory.concat(`/${file}`).replaceAll("//", "/");
        const body = fs.readFileSync(fullpath, `utf8`);
        const filedir = fullpath.split("/").reverse().slice(1).reverse().join("/");
        content = content.replace(match, replaceIncludes(body, filedir));
    }

    return content;
} 

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

    const tbl_externref = new Map();
    const key_indices = new Map();
    const object_indices = new Map();
    const parent_indices = new Map();

    tbl_externref.set("null", tbl_externref.size)
    tbl_externref.set("$self", tbl_externref.size)
    tbl_externref.set("$Reflect.get", tbl_externref.size)
    tbl_externref.set("$Reflect.getOwnPropertyDescriptor", tbl_externref.size)
    tbl_externref.set("$Function.bind", tbl_externref.size)
    tbl_externref.set("$Function.call", tbl_externref.size)

    const self = content
        ?.match(/\$self([a-z0-9\.\:\_])*(\[(get|set)\])*/ig)
        ?.map(m => m.replaceAll(/\:/g, `.prototype.`))
        ?.filter((m,i,t) => t.lastIndexOf(m) === i)
        ;

    const keys = self
        ?.concat(
            "Reflect", "get", "getOwnPropertyDescriptor", 
            "Function", "bind", "call", 
            "get", "set", "length", "name"
        )
        ?.flatMap(m => m.match(/([a-z0-9]+)/gi))
        ?.filter((m,i,t) => t.lastIndexOf(m) === i)
        ?.sort((a,b) => a.length - b.length)
        ?.filter((m,i,t) => m.length > 1)
        ;

    let buffer = Buffer.alloc(4096); 
    const begin = 8;
    let dataOffset = begin;
    let tblIndex = 4;
    let importIndex = 1;
    
    let tbl_string_from = new Array();
    let len_string_from = 0;

    let keyIndex = tblIndex;

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

    const keysPadding = 4 - get_keys_length() % 4; 
    add_keys_length( keysPadding );

    dataOffset += keysPadding;

    const OFFSET_SELF_HEADER = dataOffset;
    const BEGIN_SELF_EXT_COUNT = 0;
    const BEGIN_SELF_FUN_COUNT = 4;
    const BEGIN_SELF_COUNT = 8;
    const BEGIN_SELF_DATA = dataOffset += 16;

    const get_self_ext_count   = () => buffer.readUint16LE(OFFSET_SELF_HEADER + BEGIN_SELF_EXT_COUNT);
    const set_self_ext_count   = (value = 0) => buffer.writeUint16LE(value, OFFSET_SELF_HEADER + BEGIN_SELF_EXT_COUNT);
    const add_self_ext_count   = (value = 1) => {
        const idx = get_self_ext_count();
        set_self_ext_count( idx + value );
        return idx;
    };

    const get_self_fun_count   = () => buffer.readUint16LE(OFFSET_SELF_HEADER + BEGIN_SELF_EXT_COUNT);
    const set_self_fun_count   = (value = 0) => buffer.writeUint16LE(value, OFFSET_SELF_HEADER + BEGIN_SELF_EXT_COUNT);
    const add_self_fun_count   = (value = 1) => {
        const idx = get_self_ext_count();
        set_self_ext_count( idx + value );
        return idx;
    };

    const get_self_count    = () => buffer.readUint16LE(OFFSET_SELF_HEADER + BEGIN_SELF_COUNT);
    const set_self_count    = (value = 0) => buffer.writeUint16LE(value, OFFSET_SELF_HEADER + BEGIN_SELF_COUNT);
    const add_self_count    = (value = 1) => set_self_count( get_self_count() + value );

    set_self_ext_count(1);
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
    const set_extref_func_$bind  = (offset) => set_extref_func_key("$Function.bind", offset);
    const set_extref_func_$rget  = (offset) => set_extref_func_key("$Reflect.get", offset);
    const set_extref_func_$desc  = (offset) => set_extref_func_key("$Reflect.getOwnPropertyDescriptor", offset);

    const get_extref_this_index  = (offset) => buffer.readUint16LE(offset + BEGIN_EXTREF_THIS_INDEX);
    const set_extref_this_index  = (value, offset) => buffer.writeUint16LE(value, offset + BEGIN_EXTREF_THIS_INDEX);
    const set_extref_this_key    = (key, offset) => set_extref_this_index(tbl_externref.get(key), offset);
    const set_extref_this_$call  = (offset) => set_extref_this_key("$Function.call", offset);
    const set_extref_this_null   = (offset) => set_extref_this_key("null", offset);

    const get_extref_arg0_index  = (offset) => buffer.readUint16LE(offset + BEGIN_EXTREF_ARG0_INDEX);
    const set_extref_arg0_index  = (value, offset) => buffer.writeUint16LE(value, offset + BEGIN_EXTREF_ARG0_INDEX);
    const set_extref_arg0_key    = (key, offset) => set_extref_arg0_index( tbl_externref.get(key), offset );
    const set_extref_arg0_$self  = (offset) => set_extref_arg0_key( "$self", offset );

    const get_extref_arg1_index  = (offset) => buffer.readUint16LE(offset + BEGIN_EXTREF_ARG1_INDEX);
    const set_extref_arg1_index  = (value, offset) => buffer.writeUint16LE(value, offset + BEGIN_EXTREF_ARG1_INDEX);
    const set_extref_arg1_key    = (key, offset) => set_extref_arg1_index( tbl_externref.get(key), offset );
    const set_extref_arg1_null   = (offset) => set_extref_arg1_key( "null", offset );

    const get_extref_output_idx  = (offset) => buffer.readUint16LE(offset + BEGIN_EXTREF_OUTPUT_IDX);
    const set_extref_output_idx  = (value, offset) => buffer.writeUint16LE(value, offset + BEGIN_EXTREF_OUTPUT_IDX);
    const add_extref_output_idx  = (key, offset) => {
        if (tbl_externref.has(key)) {
            return tbl_externref.get(key);
        }

        const index = tbl_externref.size; 
        set_extref_output_idx(index, offset);
        tbl_externref.set(key, index);

        return index;
    };

    const get_extref_import_ext  = (offset) => buffer.readUint16LE(offset + BEGIN_EXTREF_IMPORT_EXT);
    const set_extref_import_ext  = (value, offset) => buffer.writeUint16LE(value, offset + BEGIN_EXTREF_IMPORT_EXT);

    const get_extref_import_fun  = (offset) => buffer.readUint16LE(offset + BEGIN_EXTREF_IMPORT_FUN);
    const set_extref_import_fun  = (value, offset) => buffer.writeUint16LE(value, offset + BEGIN_EXTREF_IMPORT_FUN);

    const set_extref_to_$bind    = (func_extref_i, offset) => {
        set_extref_func_$bind(offset);
        set_extref_this_$call(offset);
        set_extref_arg0_index(func_extref_i, offset);
        set_extref_arg1_null(offset);

        return offset + BYTES_PER_EXTERNREF_STEP;
    }

    const pathwalkers = self
        .map(k => k.split("."))
        .flatMap(s => s.map((w,i,p) => p.slice(0,i).concat(w).join(".")))
        .filter((m,i,t) => m !== "$self" && t.lastIndexOf(m) === i)
        .sort()
        ;

    dataOffset = BEGIN_SELF_DATA;

    for (const fullpath of pathwalkers) {
        let parts = fullpath.split(".");
        let [key, dkey] = parts.pop().match(/(.[^\[]*)(?:\[(get|set|value)\]*)*/).slice(1);
        let parent = parts.join(".");
        let parent_i = tbl_externref.get(parent);

        if (dkey) {
            parent = parent.concat(key);

            set_extref_func_$desc(dataOffset);
            set_extref_this_null(dataOffset);
            set_extref_arg0_index(parent_i, dataOffset);
            set_extref_arg1_key(key, dataOffset);
            add_extref_output_idx(parent, dataOffset);
            
            key = dkey;
            parent_i = get_extref_output_idx(dataOffset);
            dataOffset += BYTES_PER_EXTERNREF_STEP;

            add_self_count();
        }

        set_extref_func_$rget(dataOffset);
        set_extref_this_null(dataOffset);
        set_extref_arg0_index(parent_i, dataOffset);
        set_extref_arg1_key(key, dataOffset);
        add_extref_output_idx(fullpath, dataOffset);

        if (content.replaceAll(/\:/g, `.prototype.`).match(new RegExp(`\\(ref\\.extern\\s+${fullpath.replace(/([^a-z0-9])/ig, '\\$1')}\\)`))) {
            console.log(key)
            set_extref_import_ext(add_self_ext_count(1), dataOffset);
        }

        if (content.replaceAll(/\:/g, `.prototype.`).match(new RegExp(`\\((call|ref\\.func)\\s+${fullpath.replace(/([^a-z0-9])/ig, '\\$1')}\\)`))) {
            console.log(key)
            set_extref_import_fun(add_self_fun_count(1), dataOffset);
        }

        add_self_count();

        dataOffset += BYTES_PER_EXTERNREF_STEP;
    }

    buffer = buffer.subarray(0, dataOffset);

    const data = buffer.toString('hex').replaceAll(/(..)/g, `\\$1`);
    const size = Math.ceil(buffer.byteLength / 65536); 
    
    const code = `
    (module
        (import "self" "self"           (global $self externref))
        (import "Array" "of"            (func $array (param externref externref) (result externref)))
        (import "Reflect" "set"         (func $set (param externref i32 i32)))
        (import "Reflect" "get"         (func $get (param externref externref) (result externref)))
        (import "Reflect" "apply"       (func $apply (param externref externref externref) (result externref)))
        (import "String" "fromCharCode" (global $strf externref))

        ;; (import "console" "log"         (func $logi (param i32)))
        ;; (import "console" "log"         (func $loge (param externref)))
        (import "console" "warn"         (func $warni3 (param externref i32 i32 i32)))

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

            (local.set $apply_args  (call $array (ref.null extern) (ref.null extern)))
            (local.set $keys_length (i32.load16_u offset=${BEGIN_KEYS_LENGTH} (i32.const ${OFFSET_KEYS_HEADER})))
            (local.set $keys_count  (i32.load16_u offset=${BEGIN_KEYS_COUNT} (i32.const ${OFFSET_KEYS_HEADER})))
            (local.set $ptr*        (i32.const ${BEGIN_KEYS_DATA}))

            (loop $keys
                (local.set $key_length  (i32.load8_u offset=${BEGIN_KEY_LENGTH} (local.get $ptr*)))                
                (local.set $key_index   (i32.load8_u offset=${BEGIN_KEY_INDEX} (local.get $ptr*)))                
                (local.set $data_index  (i32.const 0))

                (loop $at
                    (local.set $data_value (i32.load8_u offset=${BEGIN_KEY_DATA} (local.get $ptr*)))                
                    (call $set (local.get $apply_args) (local.get $data_index) (local.get $data_value))
                    (local.set $ptr* (i32.add (i32.const 1) (local.get $ptr*))) 
                    (local.set $data_index (i32.add (i32.const 1) (local.get $data_index))) 
                    (br_if $at (i32.lt_u (local.get $data_index) (local.get $key_length)))
                )

                (local.set $ptr* (i32.add (i32.const ${LENGTH_KEY_HEADER}) (local.get $ptr*))) 
                (local.set $keys_index (i32.add (i32.const 1) (local.get $keys_index)))  
                (local.set $key_string (call $apply (global.get $strf) (ref.null extern) (local.get $apply_args)))
                (table.set $self (local.get $key_index) (local.get $key_string))

                (br_if $keys (i32.lt_u (local.get $keys_index) (local.get $keys_count)))
            )
        )

        (func $funcs
            (local $super externref)
            (local $key externref)
            (local $id i32)

            (local.set $super
                (call $get 
                    (table.get (i32.const ${tbl_externref.get("$self")}))
                    (table.get (i32.const ${tbl_externref.get("Reflect")}))
                )
            )

            (local.set $id (i32.const ${tbl_externref.get("$Reflect.get")}))
            (local.set $key (table.get $self (i32.const ${tbl_externref.get("get")})))
            (table.set $self (local.get $id) (call $get (local.get $super) (local.get $key)))

            (local.set $id (i32.const ${tbl_externref.get("$Reflect.getOwnPropertyDescriptor")}))
            (local.set $key (table.get $self (i32.const ${tbl_externref.get("getOwnPropertyDescriptor")})))
            (table.set $self (local.get $id) (call $get (local.get $super) (local.get $key)))

            (local.set $super
                (call $get 
                    (table.get (i32.const ${tbl_externref.get("$self")}))
                    (table.get (i32.const ${tbl_externref.get("Function")}))
                )
            )

            (local.set $id (i32.const ${tbl_externref.get("$Function.bind")}))
            (local.set $key (table.get $self (i32.const ${tbl_externref.get("bind")})))
            (table.set $self (local.get $id) (call $get (local.get $super) (local.get $key)))

            (local.set $id (i32.const ${tbl_externref.get("$Function.call")}))
            (local.set $key (table.get $self (i32.const ${tbl_externref.get("call")})))
            (table.set $self (local.get $id) (call $get (local.get $super) (local.get $key)))
        )

        (func $apply_extref 
            (param $func        i32)
            (param $this        i32)
            (param $arg0        i32)
            (param $arg1        i32)
            (result       externref)

            (call $apply 
                (table.get $self (local.get $func)) 
                (table.get $self (local.get $this)) 
                (call $array
                    (table.get $self (local.get $arg0))
                    (table.get $self (local.get $arg1))
                )
            )
        )

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

            (local.set $count   (i32.load offset=${OFFSET_SELF_HEADER} (i32.const ${BEGIN_SELF_COUNT})))
            (local.set $ptr*    (i32.const ${BEGIN_SELF_DATA}))

            (loop $at
                (local.set $func (i32.load16_u offset=${BEGIN_EXTREF_FUNC_INDEX} (local.get $ptr*)))
                (local.set $this (i32.load16_u offset=${BEGIN_EXTREF_THIS_INDEX} (local.get $ptr*)))
                (local.set $arg0 (i32.load16_u offset=${BEGIN_EXTREF_ARG0_INDEX} (local.get $ptr*)))
                (local.set $arg1 (i32.load16_u offset=${BEGIN_EXTREF_ARG1_INDEX} (local.get $ptr*)))

                (local.set $output_idx (i32.load16_u offset=${BEGIN_EXTREF_OUTPUT_IDX} (local.get $ptr*)))
                (local.set $import_ext (i32.load16_u offset=${BEGIN_EXTREF_IMPORT_EXT} (local.get $ptr*)))
                (local.set $import_fun (i32.load16_u offset=${BEGIN_EXTREF_IMPORT_FUN} (local.get $ptr*)))
                (local.set $reserved_2 (i32.load16_u offset=${BEGIN_EXTREF_RESERVED_2} (local.get $ptr*)))

                (call $warni3
                    (table.get (local.get $arg1))
                    (local.get $output_idx)
                    (local.get $import_ext)
                    (local.get $import_fun)
                )

                (local.set $ext# (call $apply_extref (local.get $func) (local.get $this) (local.get $arg0) (local.get $arg1)))
                (table.set $self (local.get $output_idx) (local.get $ext#))
                (local.set $ptr* (i32.add (local.get $ptr*) (i32.const ${BYTES_PER_EXTERNREF_STEP})))
                
                (local.set $i (i32.add (i32.const 1) (local.get $i))) 
                (br_if $at (i32.lt_u (local.get $i) (local.get $count)))
            )
        )

        (func $main
            (call $keys)
            (call $funcs)
            (call $pathwalk)
            
            (; $loge 
                (call $apply
                    (table.get $self (i32.const ${tbl_externref.get("$Function.bind")}))
                    (table.get $self (i32.const ${tbl_externref.get("$Function.call")}))
                    (call $array
                        (call $apply
                            (table.get $self (i32.const ${tbl_externref.get("$Reflect.get")}))
                            (table.get $self (i32.const ${tbl_externref.get("null")}))
                            (call $array
                                (call $apply
                                    (table.get $self (i32.const ${tbl_externref.get("$Reflect.getOwnPropertyDescriptor")}))
                                    (table.get $self (i32.const ${tbl_externref.get("null")}))
                                    (call $array
                                        (table.get $self (i32.const ${tbl_externref.get("$self")}))
                                        (table.get $self (i32.const ${tbl_externref.get("name")}))
                                    )
                                )
                                (table.get $self (i32.const ${tbl_externref.get("set")}))
                            )
                        )
                        (table.get $self (i32.const ${tbl_externref.get("null")}))
                    )
                )
            ;)
        )
        
        (table $self ${tbl_externref.size} externref)

        (elem (i32.const 0) externref (ref.null extern) (global.get 0))
        (data (i32.const 0) "${data}")

        (start $main)
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
