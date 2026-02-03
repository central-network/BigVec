(module
    (import "self" "funcref" (table $func 4 10 funcref))
    (import "self" "externref" (table $extern 4 10 externref))

    (start $test)

    (elem $funcs funcref
        (ref.func $onmessage)
    )

    (func $test
        (call $log (table.get $extern (i32.const 1)))
        (call $log (table.get $extern (i32.const 2)))
        (call $listen 
            (table.get $extern (i32.const 1))
            (table.get $extern (i32.const 2))
            (ref.func $onmessage)
        )
    )

    (func $onmessage
        (param $event externref)
        (call $log (call $get_data (local.get 0)))
    )

    (func $listen
        (param externref externref funcref)
        (result)

        (local.get 0)
        (local.get 1)
        (local.get 2)
        (call_indirect $func
            (param externref externref funcref)
            (result)
            (i32.const 2)
        )
    )

    (func $get_data
        (param externref)
        (result externref)

        (local.get 0)
        (call_indirect $func
            (param externref)
            (result externref)
            (i32.const 1)
        )
    )

    (func $log
        (param externref)

        (local.get 0)
        (call_indirect $func
            (param externref)
            (result)
            (i32.const 3)
        )
    )
)