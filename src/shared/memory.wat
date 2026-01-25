    
    (import "shared_memory" "memory" (memory $shared 1 65536 shared))
    
    (func $malloc
        (param $length  i32)
        (result         i32)

        (i32.atomic.rmw.add i32(4) (local.get $length))
    )