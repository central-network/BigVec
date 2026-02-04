(module
    (import "0" "funcref" (table $funcref 4 65536 funcref))
    (import "0" "externref" (table $externref 14 65536 externref))

    (type $log_ext (func (param externref) (result)))

    (elem $funcs funcref
        (ref.func $onmessage)
    )

    (func $main
        (call_indirect $funcref 
            (param externref externref funcref)
            (result)

            (table.get $externref (i32.const 1))
            (table.get $externref (i32.const 3))
            (ref.func $onmessage)
            (i32.const 1)
        )

    )

    (func $onmessage
        (param $event externref)

        (call_indirect $funcref
            (type $log_ext)

            (call_indirect $funcref
                (param externref)
                (result externref)

                (local.get $event)
                (i32.const 3)
            )
            (i32.const 2)
        )


        (table.get $externref (i32.const 2))
        (drop)

        (table.get $externref (i32.const 4))
        (drop)
    )

    (start $main)
)