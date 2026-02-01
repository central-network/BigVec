(module 
    (include "shared/memory.wat")

    (main $core
        (console $log<ext.ext> (text "hello from worker module!") (self))

    )
)