(module
    (elem $funcs funcref
        (ref.func $onmessage)
    )

    (func $onmessage
        (param $event externref)

        (call_direct $console.warn
            (param externref externref externref) 
            (result)

            (ref.null extern)
            (call_direct $MessageEvent:data[get]
                (param externref)
                (result externref)

                (local.get $event)
            )
            (text "Özgür Fırat Özpolat")
        )
    )
    
    (start $main
        (call_direct $EventTarget:addEventListener 
            (param externref externref funcref)
            (result)

            (self)
            (text "message")
            (ref.func $onmessage)
        )
    )
)