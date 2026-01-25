(module
    (data $master.wasm "wasm://master.wat")
    (data $worker.wasm "wasm://worker.wat")
    (data $worker_calc.wasm "wasm://worker_calc.wat")

    (data $idb.wasm "file://../wasm/idb.wasm")
    (data $uuid.wasm "file://../wasm/uuid.wasm")
    (data $worker.js "file://worker.js")

    (global $idb.wasm     mut ext)
    (global $uuid.wasm    mut ext)
    (global $master.wasm  mut ext)
    (global $worker.wasm  mut ext)
    (global $worker_calc.wasm  mut ext)
    (global $worker.js    mut ext)

    (global $exports mut ext)

    (func 
        (export "init")
        (result <Promise>)

        (async.ext
            (array $fromAsync<ext>ext
                (array $of<ext.ext.ext.ext.ext>ext
                    (call $compile (data.view $idb.wasm))
                    (call $compile (data.view $uuid.wasm))
                    (call $compile (data.view $master.wasm))
                    (call $compile (data.view $worker.wasm))    
                    (call $compile (data.view $worker_calc.wasm))    
                )
            )
            (then $oncompile 
                (param $module/s <Array>)
                (result <Promise>)
                
                (global.set $idb.wasm           (call $at (this) i32(0)))
                (global.set $uuid.wasm          (call $at (this) i32(1)))
                (global.set $master.wasm        (call $at (this) i32(2)))
                (global.set $worker.wasm        (call $at (this) i32(3)))
                (global.set $worker_calc.wasm   (call $at (this) i32(4)))

                (global.set $exports     (call $base_object))

                (array $fromAsync<ext>ext
                    (array $of<ext.ext>ext
                        (call $instantiate (global.get $idb.wasm))
                        (call $instantiate (global.get $uuid.wasm))
                    )
                )
            )
            (then $oninstance
                (param $instance/s <Array>)
                (result <Promise>)

                (call $assign (text "idb")    (call $exports (call $at (this) i32(0))))
                (call $assign (text "uuid")   (call $exports (call $at (this) i32(1))))
                (call $assign (text "module") 
                    (object $fromEntries<ext>ext
                        (array $of<ext.ext.ext.ext>ext
                            (array $of<ext.ext>ext (text "worker_calc") (global.get $worker_calc.wasm))
                            (array $of<ext.ext>ext (text "worker") (global.get $worker.wasm))
                            (array $of<ext.ext>ext (text "uuid") (global.get $uuid.wasm))
                            (array $of<ext.ext>ext (text "idb") (global.get $idb.wasm))
                        )
                    )
                )

                (call $assign (text "script") 
                    (object $fromEntries<ext>ext
                        (array $of<ext>ext
                            (array $of<ext.ext>ext (text "worker") (data.href $worker.js))
                        )
                    )
                )

                (call $instantiate (global.get $master.wasm))
            )
            (then $onselfready
                (param $master <Instance>)
                (result <Object>)

                (call $remove (text "idb"))
                (call $remove (text "uuid"))
                (call $remove (text "module"))
                (call $remove (text "script"))

                (object $assign<ext.ext>ext
                    (global.get $exports)
                    (call $exports (this))
                )
            )   
        )
    )

    (func $base_object
        (result         <TurboUUIDBase>)
        (local $object         <Object>)

        (local.set $object (object $create<ext>ext (object)))

        (reflect $defineProperty<ext.ext.ext>
            (reflect $getPrototypeOf<ext>ext (this))
            (ref.extern $Symbol.toStringTag)
            (object $fromEntries<ext>ext
                (array $of<ext>ext
                    (array $of<ext.ext>ext 
                        (text "value") (text "TurboUUIDBase")
                    )
                )
            )
        )

        (this)
    )

    (include "include/helpers.wat")
)