(module 
    (data $idb.wasm "file://../wasm/idb.wasm")
    (data $uuid.wasm "file://../wasm/uuid.wasm")
    (data $import.wasm "file://../wasm/import.wasm")
    (data $console.wasm "file://../wasm/console.wasm")

    (global $wasm new Object)

    (global $idb.wasm mut ext)
    (global $uuid.wasm mut ext)
    (global $import.wasm mut ext)
    (global $console.wasm mut ext)

    (main $portal
        (set.extern (self) (text "wasm") (wasm))

        (async 
            (array $fromAsync<ext>ext
                (array $of<ext.ext.ext.ext>ext
                    (wasm.compile (data.view $idb.wasm))
                    (wasm.compile (data.view $uuid.wasm))
                    (wasm.compile (data.view $import.wasm))
                    (wasm.compile (data.view $console.wasm))
                )
            )
            (then $onallmodulecompile
                (param $module/s             <Array>)
                (result                    <Promise>)

                (global.set $idb.wasm (get.i32_extern (this) i32(0)))
                (global.set $uuid.wasm (get.i32_extern (this) i32(1)))
                (global.set $import.wasm (get.i32_extern (this) i32(2)))
                (global.set $console.wasm (get.i32_extern (this) i32(3)))

                (wasm.instantiate (global.get $import.wasm) (self))
            )
            (then $onimportinstance
                (param $instance    <Object|Instance>)
                (result                     <Promise>)

                (call $assign (wasm.exports (this)))

                (drop (call $extref (self)))
                (drop (call $extref (wasm)))

                (call $define (text "module.idb") (global.get $idb.wasm))
                (call $define (text "module.uuid") (global.get $uuid.wasm))
                (call $define (text "module.import") (global.get $import.wasm))
                (call $define (text "module.console") (global.get $console.wasm))

                (wasm.instantiate (global.get $console.wasm) (self))
            )
            (then $onconsoleinstance
                (param $instance           <Instance>)
                (result                     <Promise>)

                (console $warn<ext.ext> (text "console started") (this))
                (wasm.instantiate (global.get $idb.wasm) (self))
            )
            (then $onidbinstance
                (param $instance           <Instance>)
                (result                     <Promise>)

                (console $warn<ext.ext> (text "idb started") (this))
                (wasm.instantiate (global.get $uuid.wasm) (self))
            )
            (then $onuuidinstance
                (param $instance           <Instance>)

                (console $warn<ext.ext> (text "uuid started") (this))
            )
        )
    )

    (func $assign
        (param $value      <Object>)

        (reflect $apply<ext.ext.ext> 
            (ref.extern $Object.assign)
            (ref.extern $Object)
            (array $of<ext.ext>ext (wasm) (this))
        )
    )

    (func $define
        (param $key        <String>)
        (param $value     externref)

        (reflect $set<ext.ext.i32> 
            (wasm) 
            (local.get $key)
            (call $extref (local.get $value))
        )
    )

    (func $extref
        (param $key        <String>)
        (result                 i32)

        (reflect $apply<ext.ext.ext>i32 
            (ref.extern $WebAssembly.Table:grow) 
            (get.extern (wasm) (text "#externref"))
            (array $of<i32.ext>ext (true) (this))
        )
    )
)