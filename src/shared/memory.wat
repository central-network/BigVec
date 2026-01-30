    
    (import "wasm" "#memory" (memory $memory 1 65536 shared))
    
    (func $malloc
        (param $length  i32)
        (result         i32)

        (i32.atomic.rmw.add i32(4) (local.get $length))
    )