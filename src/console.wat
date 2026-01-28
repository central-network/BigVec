(module
    (table $command 1 65536 externref)

    (global $proxy mut ext)
    (global $values mut ext)

    (func $demo
        (local $cmd_index i32)

        (local.set $cmd_index
            (call $register_command 
                (text "whoami") 
                (call $self.Object<fun>ext (ref.func $whoami))
            )
        )

        (call $define_parameter (local.get $cmd_index) (text "name") (text "n"))
        (call $define_parameter (local.get $cmd_index) (text "force") (null))
        (call $define_parameter (local.get $cmd_index) (text "p") (null))
        (call $define_parameter (local.get $cmd_index) (text "list") (text "l"))


        (local.set $cmd_index
            (call $register_command 
                (text "ping") 
                (call $self.Object<fun>ext (ref.func $ping))
            )
        )

        (call $define_parameter (local.get $cmd_index) (text "time") (text "t"))
    )

    (main $console
        (local $cmd_index i32)
        
        (global.set $proxy (call $new_proxy))
        (global.set $values (array))

        (call $demo)
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
            (global.get $values)
            (local.get $arguments)
        )

        (global.get $proxy)
    )

    (func $reset 
        (local $ownKeys                <Array>)

        (local.set $ownKeys
            (reflect $ownKeys<ext>ext (global.get $values))
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
                        (global.get $values)
                    )
                )
            )
        )

        (reflect $set<ext.ext.i32> 
            (global.get $values) 
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
                    (global.get $values) 
                    (array $of<i32>ext (call $toNumber (local.get $prop)))
                )
            )
            (else 
                (reflect $apply<ext.ext.ext>
                    (ref.extern $Array:push) 
                    (global.get $values) 
                    (array $of<ext>ext (local.get $prop))
                )
            )
        )

        (global.get $proxy)
    )

    (func $new_proxy
        (result                       <Proxy>)
        (local $function           <Function>)
        (local $descriptor           <Object>)

        (local.set $function (void))
        (local.set $descriptor (object))

        (reflect $set<ext.ext.fun> (local.get $descriptor) (text "apply") (ref.func $apply_trap))
        (reflect $set<ext.ext.fun> (local.get $descriptor) (text "get") (ref.func $get_trap))
        
        (reflect $construct<ext.ext>ext
            (ref.extern $Proxy)
            (array $of<ext.ext>ext
                (local.get $function) 
                (local.get $descriptor) 
            )
        )
    )

    (func $ping
        (param $arguments    <Array>)
        (console $warn<ext.ext> 
            (text "ping function triggered from console with arguments:") 
            (this)
        )    
    )

    (func $whoami
        (param $arguments    <Array>)
        (console $warn<ext.ext> 
            (text "whoami function triggered from console with arguments:") 
            (this)
        )    
    )

    (func $handle_request
        (param $index            i32)
        (result              <Proxy>)
        (call $reset)

        (reflect $apply<ext.ext.ext> (table.get $command (i32.add i32(1) (this))) (null) (self))
        (reflect $apply<ext.ext.ext> (table.get $command (i32.add i32(2) (this))) (null) (self))
        (reflect $apply<ext.ext.ext> (table.get $command (i32.add i32(3) (this))) (null) (self))

        (global.get $proxy)
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
            (global.get $values) 
            (array $of<ext>ext
                (reflect $apply<ext.ext.ext>ext
                    (ref.extern $String:concat)
                    (string "-")
                    (array $of<ext>ext (this))
                )
            )
        )

	    (global.get $proxy) 
    )

    (func $register_command
        (param $command     <String>)
        (param $handler   <Function>)
        (result                  i32)
        (local $index            i32)

        (local $command_bounded_getter <Function>)
        (local $queue_bounded_dispatch <Function>)
        (local $delayed_command_handle <Function>)

        (local.set $index (table.grow $command (null) i32(4)))
        (local.set $command_bounded_getter 
            (reflect $apply<ext.fun.ext>ext
                (ref.extern $Function:bind)
                (ref.func $handle_request)
                (array $of<ext.i32>ext (null) (local.get $index))
            )
        )

        (local.set $queue_bounded_dispatch 
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $Function:bind)
                (local.get $handler)
                (array $of<ext.ext>ext (null) (global.get $values))
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


        (table.set $command (i32.add i32(0) (local.get $index)) (object))
        (table.set $command (i32.add i32(1) (local.get $index)) (void))
        (table.set $command (i32.add i32(2) (local.get $index)) (local.get $delayed_command_handle))
        (table.set $command (i32.add i32(3) (local.get $index)) (void))

        (local.get $index)
    )

    (func $define_parameter
        (param $index                            i32)
        (param $parameter                   <String>)
        (param $alternative                 <String>)

        (local $command_descriptors         <Object>)
        (local $arguments_getter_bound    <Function>)
        (local $command_all_parameters       <Array>)
        (local $bound_for_define_param    <Function>)
        (local $bound_for_remove_param    <Function>)
        (local $delayed_remove_binding    <Function>)

        (local.set $command_descriptors 
            (table.get $command (this))
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

        (if (i32.eqz (ref.is_null (local.get $alternative)))
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

        (table.set $command (i32.add i32(1) (this)) (local.get $bound_for_define_param))
        (table.set $command (i32.add i32(3) (this)) (local.get $delayed_remove_binding))
    )
)