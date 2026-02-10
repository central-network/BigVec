    
    (func $test
        (param externref externref)
        (result)

        (call $console.warn
            (ref.extern $self.length[get])
            (ref.extern "hello g_in")
        )
        
    )

    (include "subf/g_in_deep.wat")
