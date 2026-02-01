(module
    (include "shared/imports.wat")
    (include "call_indirect/mt.wat")
    (include "call_indirect/console.wat")

    (main $register
        (call $console.register_command
            (text "mt")
            (ref.func $handle)
            (array $of<ext.ext.ext.ext>ext 
                (text "help")
                (text "fork")
                (text "ref")
                (text "close")
            )
        )
    )

    (func $handle
        (param $arguments <Array>)

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-close"))
            (then 
                (call $mt.close (get.i32 (this) i32(1)))
                (return)
            )
        )

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-ref"))
            (then 
                (call $mt.ref (get.i32 (this) i32(1)))
                (console $warn<ext>)
                (return)
            )
        )

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-fork"))
            (then 
                (call $mt.fork (get.i32 (this) i32(1)))
                (console $warn<i32>)
                (return)
            )
        )

        (console $table<ext>
            (array $of<ext.ext.ext.ext>ext
                (array $of<ext.ext.ext.ext>ext (text "close") (text "mt -close [[INDEX]]") (text "start close protocol for instance at given index") (text "mt -close [0]"))  
                (array $of<ext.ext.ext.ext>ext (text "ref") (text "mt -ref [[INDEX]]") (text "get Worker process instance for given index") (text "mt -ref [1]"))  
                (array $of<ext.ext.ext.ext>ext (text "fork") (text "mt -fork [?COUNT]") (text "create worker manager module instances") (text "mt -fork"))  
                (array $of<ext.ext.ext.ext>ext (text "help") (text "mt -help") (text "show this message") (text "mt -help"))  
            )
        )
    )
)