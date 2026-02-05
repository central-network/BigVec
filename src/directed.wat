(module
    (import "wasm" "funcref" (table $funcref 4 65536 funcref))
    (import "wasm" "externref" (table $externref 26 65536 externref))

    (elem $funcs funcref
        (ref.func $onmessage)
    )

    (func $onmessage
        (param $event externref)

        (call_indirect $funcref
            (param externref externref externref) 
            (result)

            (ref.null extern)
            (call_indirect $funcref
                (param externref)
                (result externref)

                (local.get $event)
                (i32.const 2)
            )

            (table.get $externref (i32.const 1)) (; "Özgür Fırat Özpol.." ;)
            (i32.const 1)
        )

    )
    
    (start $main)

	(func $main

        (call_indirect $funcref 
            (param externref externref funcref)
            (result)

            (table.get $externref (i32.const 0))
            (table.get $externref (i32.const 13)) (; "message" ;)
            (ref.func $onmessage)
            (i32.const 3)
        )

    )
)