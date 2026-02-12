(module $window
    (func $onmessage
        (param $event externref)
        (local externref)
        (local i32)

        (call $self.console.log
            (param externref externref externref externref) 
            (result)

            (ref.null extern)
            (call $self.MessageEvent:data[get]
                (param externref)
                (result externref)

                (local.get $event)
            )
            (ref.extern "Özgür Fırat Özpolat")
            (ref.extern $self.location.href)
        )
    )

    (elem funcref (ref.func $onmessage))

    (func start $init

        (call $self.EventTarget:addEventListener
            (param externref externref funcref)
            (result)

            (self)
            (ref.extern "message")
            (ref.func $onmessage)
        )
  )
)
