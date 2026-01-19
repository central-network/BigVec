(module 
    (func $main
        (ref.func $unreferenced_by_user)
        (drop)
    )

    (func $test_inline
        (func $inline
            (local $a i32)
            (local.set $a (i32.const 2))
        )
    )

    (func $unreferenced_by_user)
)