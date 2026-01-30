(module
    (include "shared/memory.wat")
    (include "shared/imports.wat")

    (global $proxy mut i32)
    (global $values mut i32)
    (global $exports mut i32)
    (global $commands mut i32)
    
    (main $console
        (global.set $proxy (table.add $externref (call $new_proxy) (true)))
        (global.set $values (table.add $externref (array) (true)))
        (global.set $exports (table.add $externref (object) (true)))
        (global.set $commands (table.add $externref (object) (true)))

        (wasm.export (ref.module $console) (ref.func $register_command))
        (wasm.export (ref.module $console) (ref.func $unregister_command))
        (wasm.export (ref.module $console) (ref.func $define_parameter))
    )

    (func $isToPrimitive 
        (param $prop    <String|Number|Symbol>)
        (result                            i32)

        (object $is<ext.ext>i32
            (ref.extern $Symbol.toPrimitive)
            (this)
        )
    )

    (func $isNumberValue 
        (param $prop    <String|Number|Symbol>)
        (result                            i32)

        (reflect $apply<ext.ext.ext>i32
            (ref.extern $isNaN)
            (null)
            (array $of<ext>ext (local.get $prop))
        )

        (i32.eqz)
    )

    (func $toNumber
        (param $value                <Number>)
        (result                           i32)

        (reflect $apply<ext.ext.ext>i32
            (ref.extern $Number)
            (null)
            (array $of<ext>ext (this))
        )
    )

    (func $apply_trap
        (param $target                 <Proxy>)
        (param $thisArg               <Object>)
        (param $arguments              <Array>)
        (result                        <Proxy>)

        (local.set $arguments
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $Array:flat)
                (array $from<ext>ext (local.get $arguments))
                (array)
            )
        )

        (reflect $apply<ext.ext.ext>
            (ref.extern $Array:push)
            (table.get $externref (global.get $values))
            (local.get $arguments)
        )

        (table.get $externref (global.get $proxy))
    )

    (func $reset 
        (local $ownKeys <Array>)

        (local.set $ownKeys
            (reflect $ownKeys<ext>ext 
                (table.get $externref (global.get $values))
            )
        )

        (reflect $apply<ext.ext.ext>
            (ref.extern $Array:forEach)
            (local.get $ownKeys)
            (array $of<ext>ext 
                (reflect $apply<ext.ext.ext>ext
                    (ref.extern $Function:bind)
                    (ref.extern $Reflect.deleteProperty)
                    (array $of<ext.ext>ext 
                        (null) 
                        (table.get $externref (global.get $values))
                    )
                )
            )
        )

        (reflect $set<ext.ext.i32> 
            (table.get $externref (global.get $values)) 
            (text "length") 
            (i32.const 0)
        )
    )

    (func $get_trap
        (param $target                 <Proxy>)
        (param $prop    <String|Number|Symbol>)
        (result               <Proxy|Function>)

        (if (call $isToPrimitive (local.get $prop))
            (then (return (ref.extern $Number)))
        )

        (if (call $isNumberValue (local.get $prop))
            (then 
                (reflect $apply<ext.ext.ext>
                    (ref.extern $Array:push) 
                    (table.get $externref (global.get $values)) 
                    (array $of<i32>ext (call $toNumber (local.get $prop)))
                )
            )
            (else 
                (reflect $apply<ext.ext.ext>
                    (ref.extern $Array:push) 
                    (table.get $externref (global.get $values)) 
                    (array $of<ext>ext (local.get $prop))
                )
            )
        )

        (table.get $externref (global.get $proxy))
    )

    (func $void (result i32) (false))

    (func $new_proxy
        (result                       <Proxy>)
        (local $function           <Function>)
        (local $descriptor           <Object>)

        (local.set $function (call $self.Object<fun>ext (ref.func $void)))
        (local.set $descriptor (object))

        (reflect $set<ext.ext.fun> (local.get $descriptor) (text "apply") (ref.func $apply_trap))
        (reflect $set<ext.ext.fun> (local.get $descriptor) (text "get") (ref.func $get_trap))

        (reflect $deleteProperty<ext.ext> (this) (text "name"))
        (reflect $deleteProperty<ext.ext> (this) (text "length"))
        (reflect $deleteProperty<ext.ext> (reflect $getPrototypeOf<ext>ext (this)) (text "arguments"))
        (reflect $deleteProperty<ext.ext> (reflect $getPrototypeOf<ext>ext (this)) (text "caller"))
        
        (reflect $construct<ext.ext>ext
            (ref.extern $Proxy)
            (array $of<ext.ext>ext
                (local.get $function) 
                (local.get $descriptor) 
            )
        )
    )

    (func $handle_request
        (param $index i32)
        (result     <NaN>)
        (call $reset)

        (reflect $apply<ext.ext.ext> (table.get $externref (i32.add i32(1) (this))) (null) (self))
        (reflect $apply<ext.ext.ext> (table.get $externref (i32.add i32(2) (this))) (null) (self))
        (reflect $apply<ext.ext.ext> (table.get $externref (i32.add i32(3) (this))) (null) (self))

        (NaN)
    )

    (func $create_getter_descriptor
        (param $handler   <Function>)
        (result             <Object>)
        (local $descriptor  <Object>)

        (local.set $descriptor (object))
        (reflect $set<ext.ext.i32> (local.get $descriptor) (text "configurable") (true))
        (reflect $set<ext.ext.ext> (local.get $descriptor) (text "get") (this))
        (local.get $descriptor)
    )

    (func $parameter_trap
        (param $name        <String>)
        (result              <Proxy>)

        (reflect $apply<ext.ext.ext>
            (ref.extern $Array:push) 
            (table.get $externref (global.get $values)) 
            (array $of<ext>ext
                (reflect $apply<ext.ext.ext>ext
                    (ref.extern $String:concat)
                    (string "-")
                    (array $of<ext>ext (this))
                )
            )
        )

	    (table.get $externref (global.get $proxy)) 
    )

    (func $unregister_command
        (param $command <String>)
        (reflect $deleteProperty<ext.ext> (self) (local.get $command))
        (reflect $deleteProperty<ext.ext> (table.get $externref (global.get $commands)) (local.get $command))
    )

    (func $register_command
        (param $command     <String>)
        (param $handler      funcref)
        (param $parameters   <Array>)
        (local $index            i32)

        (local $command_bounded_getter <Function>)
        (local $queue_bounded_dispatch <Function>)
        (local $delayed_command_handle <Function>)

        (local.set $index (table.add $externref (null) i32(4)))

        (reflect $set<ext.ext.i32> 
            (table.get $externref (global.get $commands)) 
            (local.get $command) 
            (local.get $index)
        )
        
        (local.set $command_bounded_getter 
            (reflect $apply<ext.fun.ext>ext
                (ref.extern $Function:bind)
                (ref.func $handle_request)
                (array $of<ext.i32>ext (null) (local.get $index))
            )
        )

        (local.set $queue_bounded_dispatch 
            (reflect $apply<ext.fun.ext>ext
                (ref.extern $Function:bind)
                (local.get $handler)
                (array $of<ext.ext>ext (null) (table.get $externref (global.get $values)))
            )
        )

        (local.set $delayed_command_handle 
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $Function:bind)
                (ref.extern $setTimeout)
                (array $of<ext.ext>ext (null) (local.get $queue_bounded_dispatch))
            )
        )

        (reflect $defineProperty<ext.ext.ext>
            (self) 
            (local.get $command) 
            (call $create_getter_descriptor (local.get $command_bounded_getter))
        )

        (table.set $externref (i32.add i32(0) (local.get $index)) (object))
        (table.set $externref (i32.add i32(1) (local.get $index)) (void))
        (table.set $externref (i32.add i32(2) (local.get $index)) (local.get $delayed_command_handle))
        (table.set $externref (i32.add i32(3) (local.get $index)) (void))

        (if (bool (local.get $parameters))
            (then
                (reflect $apply<ext.ext.ext>
                    (ref.extern $Array:forEach)
                    (local.get $parameters)
                    (array $of<ext>ext
                        (reflect $apply<ext.fun.ext>ext
                            (ref.extern $Function:bind)
                            (ref.func $define_parameter)
                            (array $of<ext.ext>ext 
                                (null) (local.get $command)
                            )
                        )
                    )
                )
            )
        )
    )

    (func $define_parameter
        (param $command                     <String>)
        (param $parameter                   <String>)
        (param $alternative                 <String>)

        (local $index                            i32)
        (local $command_descriptors         <Object>)
        (local $arguments_getter_bound    <Function>)
        (local $command_all_parameters       <Array>)
        (local $bound_for_define_param    <Function>)
        (local $bound_for_remove_param    <Function>)
        (local $delayed_remove_binding    <Function>)
        
        (local.set $index
            (reflect $get<ext.ext>i32 
                (table.get $externref (global.get $commands)) 
                (local.get $command)
            )
        )

        (local.set $command_descriptors 
            (table.get $externref (local.get $index))
        )

        (local.set $arguments_getter_bound 
            (reflect $apply<ext.fun.ext>ext
                (ref.extern $Function:bind)
                (ref.func $parameter_trap)
                (array $of<ext.ext>ext (null) (local.get $parameter))
            )
        )

        (reflect $set<ext.ext.ext>
            (local.get $command_descriptors) 
            (local.get $parameter) 
            (call $create_getter_descriptor (local.get $arguments_getter_bound)) 
        )

        (if (i32.and
                (bool (local.get $alternative))
                (isNaN (local.get $alternative))
            )
            (then
                (reflect $set<ext.ext.ext>
                    (local.get $command_descriptors) 
                    (local.get $alternative) 
                    (call $create_getter_descriptor (local.get $arguments_getter_bound)) 
                )
            )
        )

        (local.set $command_all_parameters
            (reflect $ownKeys<ext>ext   
                (local.get $command_descriptors)
            )
        )
        
        (local.set $bound_for_define_param
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $Function:bind)
                (ref.extern $Object.defineProperties)
                (array $of<ext.ext.ext>ext 
                    (ref.extern $Object)
                    (self)
                    (local.get $command_descriptors)
                )
            )
        )

        (local.set $bound_for_remove_param 
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $Function:bind)
                (ref.extern $Array:forEach)
                (array $of<ext.ext>ext
                    (local.get $command_all_parameters) 
                    (reflect $apply<ext.ext.ext>ext
                        (ref.extern $Function:bind)
                        (ref.extern $Reflect.deleteProperty)
                        (array $of<ext.ext>ext (null) (self))
                    )
                )
            )
        )

        (local.set $delayed_remove_binding
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $Function:bind)
                (ref.extern $setTimeout)
                (array $of<ext.ext>ext 
                    (null)
                    (local.get $bound_for_remove_param) 
                )
            )
        ) 

        (table.set $externref (i32.add i32(1) (local.get $index)) (local.get $bound_for_define_param))
        (table.set $externref (i32.add i32(3) (local.get $index)) (local.get $delayed_remove_binding))
    )
)