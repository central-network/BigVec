(module
    (import "self" "funcref" (table $func 4 10 funcref))
    (import "self" "externref" (table $extern 4 10 externref))

    (start $test)

    (elem $funcs funcref
        (ref.func $onmessage)
    )

    (func $edge
        (call_direct $console.log 
            (param externref)
            (result)
            (ref.extern $self.length)
            (text "hello")
        )

        (call_direct $console.debug 
            (param externref externref)
            (result)

            (ref.extern $location.href)
            (text "test")
        )

        (call_direct $MessageEvent:data)
        (call_direct $MessageEvent:data[set])

        (call_direct $MessageEvent:data[get]
            (param externref)
            (result externref)
            
            (ref.extern $navigator.gpu)
            (ref.extern $navigator.gpu.length[get])
        )

        (call_direct $Navigator:devicePixelRatio[get]
            (param externref)
            (result externref)
            
            (ref.extern $navigator.gpu)
            (ref.extern $MessageEvent:data[get])
        )

        (ref.extern $length[get])
    )

    (func $test
        (call $log (table.get $extern (i32.const 1)))
        (call $log (table.get $extern (i32.const 2)))
        
        (call $listen 
            (table.get $extern (i32.const 1))
            (table.get $extern (i32.const 2))
            (ref.func $onmessage)
        )

        (call_direct $Promise.withResolvers
            (param externref funcref)
            (result externref)

            (ref.extern $Navigator:gpu[get])
            (ref.func $onmessage)
        )

        (call_direct $Promise:then
            (param externref funcref)
            (result externref)

            (ref.extern $Navigator:gpu[get])
            (ref.extern $Promise:)
        )

        (call_direct $Promise:catch
            (param externref funcref)
            (result externref)

            (ref.extern $Navigator:gpu[get])
            (ref.func $onmessage)
        )

        (call_direct $console.warn
            (param externref)
        )

        (call_direct $Float32Array:set
            (param i32)
            (call_direct $Promise:then
                (param externref funcref)
                (result i32)

                (ref.extern $Navigator:devicePixelRatio[get])
                (ref.extern $Navigator:devicePixelRatio[set])
                (ref.extern $navigator)
                (ref.extern $MessageEvent)
                (ref.extern $Float32Array:BYTES_PER_ELEMENT)
                (ref.global $Float32Array.BYTES_PER_ELEMENT)
                (ref.func $Uint8Array.prototype)
                (ref.func $Uint8Array.__proto__)
                (ref.func $Uint8Array:set)
                (ref.func $Uint8Array:set[get])
                (ref.func $console.log)
                (ref.global $console.log)
            )
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
        (call_direct $Navigator:devicePixelRatio[get]
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