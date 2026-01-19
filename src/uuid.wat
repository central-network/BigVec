(module
    (memory $base {{PAGE_COUNT}})

    (include "find.wat")
    (include "export.wat")
    (include "helpers.wat")

    (global $MAX_COUNT   mut i32)
    (global $UUID_COUNT  mut i32)
    (global $BLOCK_COUNT mut i32)

    (global $true  mut ext)
    (global $false mut ext)

    (export "memory"      (memory $base))
    (export "at"          (func $at))
    (export "indexOf"     (func $indexOf))
    (export "contains"    (func $contains))
    (export "count"       (func $count))
    (export "forEach"     (func $forEach))
    (export "push"        (func $push))
    (export "stats"       (func $stats))

    (global $ARGUMENTS_REGEXP_CLEAR_STR mut ext)
    (global $ARGUMENTS_REGEXP_MATCH_HEX mut ext)

    (global $stride (mut v128) (v128.const i32x4 0 0 0 0))

    (main $init
        (local $offset i32)
        (memory.size)
        (i32.mul (i32.const 65536))
        (i32.div_u (i32.const 16))
        (global.set $MAX_COUNT)

        (global.set $ARGUMENTS_REGEXP_CLEAR_STR (call $regexp_args_array (text "[^a-f0-9]") (string)))
        (global.set $ARGUMENTS_REGEXP_MATCH_HEX (call $regexp_args_array (text "(..)") (string)))

        (global.set $true (reflect $apply<ext.ext.ext>ext (ref.extern $Boolean) (null) (array $of<i32>ext (true))))
        (global.set $false (reflect $apply<ext.ext.ext>ext (ref.extern $Boolean) (null) (array $of<i32>ext (false))))
        (global.set $stride (call $calc_stride (memory.size)))
    )
)