    
    (import "wasm" "#memory" (memory $memory 1 65536 shared))
    (import "wasm" "#memory" (global $memory externref))
    
    (func $malloc
        (param $length  i32)
        (result         i32)

        (i32.atomic.rmw.add i32(4) (local.get $length))
    )

    (func $memory.buffer
        (result <SharedArrayBuffer>)

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $WebAssembly.Memory:buffer[get])
            (global.get $memory)
            (array)
        )
    )

    (func $i32.array_u
        (param $offset             i32)
        (param $length             i32)
        (result          <Uint32Array>)

        (reflect $construct<ext.ext>ext
            (ref.extern $Uint32Array)
            (array $of<ext.i32.i32>ext
                (call $memory.buffer)
                (local.get $offset)
                (i32.div_u (local.get $length) i32(4))
            )
        )
    )