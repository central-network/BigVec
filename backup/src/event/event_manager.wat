(module
    (import "self" "memory" (memory $shared 100 100 shared))

    (main $event_loop
        (console $warn<ext> (text "hello event loop"))
    )
)