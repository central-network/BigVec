(module
    (include "shared/imports.wat")
    (include "call_indirect/uuid.wat")
    (include "call_indirect/console.wat")

    (main $register_command
        (call $console.register_command
            (text "uuid")
            (ref.func $handle_command)
            (array $of<ext.ext.ext.ext.ext.ext>ext 
                (text "indexOf")
                (text "has")
                (text "count")
                (text "forEach")
                (text "push")
                (text "at")
            )
        )
    )

    (func $print_async_command_result 
        (param $call <Promise>)
        (result      <Promise>)
        
        (reflect $apply<ext.ext.ext>
            (ref.extern $Promise:then)
            (local.get $call)
            (array $of<ext>ext (ref.extern $console.warn))
        )

        (this)
    )

    (func $handle_command
        (param $arguments <Array>)

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-at"))
            (then 
                (call $uuid.at (get.i32 (this) i32(1)))
                (console $warn<i32>)
                (return)
            )
        )

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-indexOf"))
            (then 
                (call $uuid.indexOf (get.i32_extern (this) i32(1)))
                (console $warn<i32>)
                (return)
            )
        )

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-has"))
            (then 
                (call $uuid.has (get.i32_extern (this) i32(1)))
                (console $warn<i32>)
                (return)
            )
        )

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-push"))
            (then 
                (call $uuid.push (get.i32_extern (this) i32(1)))
                (console $warn<i32>)
                (return)
            )
        )

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-forEach"))
            (then 
                (call $uuid.forEach 
                    (if (result externref)
                        (reflect $has<ext.ext>i32 (ref.extern $console) (get.i32_extern (this) i32(1)))
                        (then (get.extern (ref.extern $console) (get.i32_extern (this) i32(1))))
                        (else (get.extern (self) (get.i32_extern (this) i32(1))))
                    )
                    (get.i32_extern (this) i32(2))
                )
                (return)
            )
        )

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-count"))
            (then 
                (call $uuid.count)
                (console $warn<i32>)
                (return)
            )
        )
    )
)