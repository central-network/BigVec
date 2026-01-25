(module
    (import "self" "idb"   (global $idb.wasm externref))
    (import "self" "uuid"   (global $uuid.wasm externref))
    (import "self" "worker_calc"   (global $worker_calc.wasm externref))

    (global $uuid.memory.buffer mut ext)
    (global $exports mut ext)
    
    (main $init
        (async
            (array $fromAsync<ext>ext
                (array $of<ext.ext>ext
                    (call $instantiate (global.get $idb.wasm))
                    (call $instantiate (global.get $uuid.wasm))
                )
            )
            (then $oninstances 
                (param $instance/s <Array>)
                (result <Promise>)

                (global.set $exports (object))

                (call $assign (text "idb")  (call $exports (call $at (this) i32(0))))
                (call $assign (text "uuid") (call $exports (call $at (this) i32(1))))

                (call $instantiate (global.get $worker_calc.wasm))
            )
            (then $oncalcready
                (param $instance <Instance>)
                (console $log<ext> (this))
            )
        )
    )

    (include "include/helpers.wat")
)