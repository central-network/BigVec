(module 
    (main $replace 
        (local $this f32)
        
        (this)
        (console $log<f32>)

        (self)
        (console $log<ext>)

        (null)
        (console $log<ext>)

        (func)
        (console $log<fun>)

        (true)
        (console $log<i32>)

        (false)
        (console $log<i32>)

        (NaN)
        (console $log<ext>)

        (nan)
        (console $log<f32>)

        (array)
        (console $log<ext>)

        (object)
        (console $log<ext>)

        (undefined)
        (console $log<ext>)

        (string)
        (console $log<ext>)

        (lget $this)
        (console $log<f32>)

        (gget $wat4wasm)
        (console $log<ext>)

        (tget $wat4wasm i32(0))
        (console $log<ext>)

        (grow $wat4wasm (null) i32(0))
        (drop)

        i32(2)
        (console $log<i32>)

        f32(- 2)
        (console $log<f32>)

        f32(-2.2)
        (console $log<f32>)

        f32(+ 2.2)
        (console $log<f32>)

        i64(+2)
        (console $log<i64>)
    )
)