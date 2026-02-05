(module
    (elem funcref
        (ref.func $onmessage)
    )

    (func $onmessage
        (param $event externref)

        (call_indirect $self.console.log
            (param externref externref externref externref) 
            (result)

            (ref.null extern)
            (call_indirect $self.MessageEvent:data[get]
                (param externref)
                (result externref)

                (local.get $event)
            )
            (ref.extern "Özgür Fırat Özpolat")
            (ref.extern $location.href)
        )
    )
    
    (start $main
        (call_indirect $self.EventTarget:addEventListener 
            (param externref externref funcref)
            (result)

            (ref.extern $self)
            (ref.extern "message")
            (ref.func $onmessage)
        )
    )
)