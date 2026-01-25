(module
    (include "include/imports.wat")

    (import "self" "module"   (global $module/s externref))
    (import "self" "script"   (global $script/s externref))

    (import "module" "worker" (global $worker.wasm externref))
    (import "script" "worker" (global $worker.js externref))

    (export "at"        (func $at))
    (export "get"       (func $get))
    (export "set"       (func $set))
    (export "has"       (func $has))
    (export "count"     (func $count))
    (export "random"    (func $random))
    (export "indexOf"   (func $indexOf))
    (export "forEach"   (func $forEach))
    (export "stats"     (func $stats))


    (func $at)
    (func $get)
    (func $set)
    (func $has)
    (func $count)
    (func $random)
    (func $indexOf)
    (func $forEach)
    (func $stats)

    (main $init
        (async
            (call $idb.open 
                (text "uuid") 
                (text "packet") 
                (i32.const 1)
            )
            (then $onidbopen
                (result <Promise>)
                (call $idb.get (i32.const 2))
            )
            (then $onidget
                (param $packet <ArrayBuffer>)

                (console $log<ext.ext.ext>
                    (text "master open") 
                    (global.get $module/s)
                    (global.get $script/s)
                )
            )
        )

        (call $fork)                
    )

    (func $fork
        (reflect $apply<ext.ext.ext>
            (ref.extern $Worker:postMessage)
            (reflect $construct<ext.ext>ext
                (ref.extern $Worker)
                (array $of<ext>ext (global.get $worker.js))
            )
            (array $of<ext.ext>ext
                (global.get $module/s)
                (global.get $script/s)
            )
        )
    )
)