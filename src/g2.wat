(module $idb
    (func $test
        (param externref externref)
        (result)

        (call $console.warn
            (param externref externref)
            (result)

            (self)
            (ref.extern "hello g2")
        )
    )
)
