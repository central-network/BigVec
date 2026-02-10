
    (include "../shared/g_in_any.wat")

    (func $console.warn
        (param externref externref)
        (result)

        (call $self.console.warn
            (param externref externref externref)
            (result)

            (ref.extern $self.length)
            (ref.extern $self.location.href)
        )

        (call $self.EventTarget:addEventListener
            (param externref externref funcref)
            (result)

            (self)
            (ref.extern "message")
            (ref.func $onmessage)
        )
    )
