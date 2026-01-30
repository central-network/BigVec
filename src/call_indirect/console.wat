
    (import "wasm" "console.register_command" 
    (global $console.register_command i32))
    (type   $console.register_command (func (param externref funcref externref) (result)))
    (func   $console.register_command 
    (type   $console.register_command)
        (local.get 0) (local.get 1) (local.get 2)
        (call_indirect $funcref 
            (type $console.register_command) 
            (gget $console.register_command)
        )
    )

    (import "wasm" "console.unregister_command" 
    (global $console.unregister_command i32))
    (type   $console.unregister_command (func (param externref) (result)))
    (func   $console.unregister_command 
    (type   $console.unregister_command)
        (local.get 0) 
        (call_indirect $funcref 
            (type $console.unregister_command) 
            (gget $console.unregister_command)
        )
    )

    (import "wasm" "console.define_parameter" 
    (global $console.define_parameter i32))
    (type   $console.define_parameter (func (param externref externref externref) (result)))
    (func   $console.define_parameter 
    (type   $console.define_parameter)
        (local.get 0) (local.get 1) (local.get 2) 
        (call_indirect $funcref 
            (type $console.define_parameter) 
            (gget $console.define_parameter)
        )
    )
