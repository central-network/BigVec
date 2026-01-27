(module
    (table $ext 1 65536 externref)
    (table $fun 1 65536 funcref)

    (memory 1)

    (global $OFFSET_MODULE i32 i32(8))
    (global $LENGTH_MODULE i32 i32(4096))

    (global $BEGIN_ELEMENTS_AT i32 i32(32))
    (global $BYTES_PER_ELEMENT i32 i32(16))
    (global $MAX_ELEMENT_COUNT i32 i32(254))

    (func $add_fun              (param funcref) (result i32) (table.grow $fun (this) (true)))
    (func $add_ext              (param externref) (result i32) (table.grow $ext (this) (true)))
    (func $get_fun              (param i32) (result funcref) (table.get $fun (this)))
    (func $get_ext              (param i32) (result externref) (table.get $ext (this)))
    (func $get_cmd              (param i32) (result externref) (table.get $ext (call $get_cmd_index (this))))
    (func $get_handler          (param i32) (result externref) (table.get $ext (call $get_handler_index (this))))
    (func $get_arguments        (param i32) (result externref) (table.get $ext (call $get_arguments_index (this))))

    (func $new_offset           
        (result i32)
        (i32.add
            (i32.atomic.rmw.add offset=0 
                (global.get $OFFSET_MODULE) 
                (global.get $BYTES_PER_ELEMENT)
            )
            (global.get $BEGIN_ELEMENTS_AT)
        )
    )

    (func $get_cmd_count        (result i32) (i32.load offset=4 (global.get $OFFSET_MODULE)))
    (func $set_cmd_count        (param i32) (i32.store offset=4 (global.get $OFFSET_MODULE) (local.get 0)))

    (func $get_handler_count    (result i32) (i32.load offset=8 (global.get $OFFSET_MODULE)))
    (func $set_handler_count    (param i32) (i32.store offset=8 (global.get $OFFSET_MODULE) (local.get 0)))

    (func $get_cmd_index 
        (param $offset i32) 
        (result i32) 
        (i32.load offset=0 (local.get $offset))
    )

    (func $set_cmd_index 
        (param $offset i32) 
        (param $value i32) 
        (i32.store offset=0 (local.get $offset) (local.get $value))
    )

    (func $get_handler_index 
        (param $offset i32) 
        (result i32) 
        (i32.load offset=4 (local.get $offset))
    )

    (func $set_handler_index 
        (param $offset i32) 
        (param $value i32) 
        (i32.store offset=4 (local.get $offset) (local.get $value))
    )

    (func $get_argument_count 
        (param $offset i32) 
        (result i32) 
        (i32.load offset=8 (local.get $offset))
    )

    (func $set_argument_count 
        (param $offset i32) 
        (param $value i32) 
        (i32.store offset=8 (local.get $offset) (local.get $value))
    )

    (func $add_argument_count 
        (param $offset i32) 
        (result i32) 
        (i32.atomic.rmw.add offset=8 (local.get $offset) (i32.const 1))
    )

    (func $get_arguments_index 
        (param $offset i32) 
        (result i32) 
        (i32.load offset=12 (local.get $offset))
    )

    (func $set_arguments_index 
        (param $offset i32) 
        (param $value i32) 
        (i32.store offset=12 (local.get $offset) (local.get $value))
    )

    (main $console
        (local $cmd_offset i32)
        (console $group<ext> (text "console starting.."))    
        (console $group<ext> (text "integrating"))    
        
        (local.set $cmd_offset (call $register (text "whoami") (ref.func $whoami)))
        (call $define_parameter (local.get $cmd_offset) (text "name") (text "n"))
        (drop)
        (call $define_parameter (local.get $cmd_offset) (text "list") (text "l"))
        (drop)

        (local.set $cmd_offset (call $register (text "help") (ref.func $help)))

        (console $groupEnd<ext> (text "integrating"))    
        (console $groupEnd<ext> (text "console starting.."))    
    )

    (func $whoami
        (param $request <Object>)
        (param $request2 <Object>)
        (error (local.get 0))    
        (error (local.get 1))    
    )

    (func $help
        (param $request <Object>)
        (error (this))    
    )

    (func $handle_request
        (param $offset             i32)
        (param $handler     <Function>)
        (param $arguments      <Array>)
        (result                    ext)
        (local $argument      <String>)
        (local $argc               i32)
        (local $request       <Object>)
        (local $descriptor    <Object>)
        (local $bound       <Function>)

        (console $log<ext.i32> (text "handle_request offset:") (this))
        (console $log<ext.ext> (text "handle_request cmd:") (call $get_cmd (this)))
        (console $log<ext.ext> (text "handle_request handler:") (call $get_handler (this)))
        (console $log<ext.i32> (text "handle_request argc:") (call $get_argument_count (this)))
        (console $log<ext.ext> (text "handle_request definer:") (call $get_arguments (this)))

        (global.set $values (array))
        (object $defineProperties<ext.ext> (self) (call $get_arguments (this)))

        (reflect $apply<ext.ext.ext>
            (ref.extern $setTimeout)
            (null)
            (array $of<ext>ext
                (reflect $apply<ext.ext.ext>ext
                    (ref.extern $Function:bind)
                    (call $get_handler (this))
                    (array $of<ext.ext>ext 
                        (null) (global.get $values)
                    )
                )
            )
        )

        (null)
        (return)

        (local.set $request (object))

        (reflect $set<ext.ext.i32> (local.get $request) (text "cmd") (this))
        
        (if (local.tee $argc 
                (reflect $get<ext.ext>i32 
                    (local.get $arguments) 
                    (text "length")
                )
            )
            (then
                (local.set $descriptor (object))
                
                (reflect $set<ext.ext.i32> 
                    (local.get $descriptor) 
                    (text "configurable") 
                    (true)
                )
                
                (loop $bind_argument
                    (local.set $argc (i32.sub (local.get $argc) i32(1)))
                    
                    (local.set $argument 
                        (reflect $get<ext.i32>ext 
                            (local.get $arguments) 
                            (local.get $argc)
                        )
                    )

                    (reflect $set<ext.ext.ext> 
                        (local.get $descriptor) 
                        (text "get") 
                        (reflect $apply<ext.fun.ext>ext
                            (ref.extern $Function:bind)
                            (ref.func $handle_argument)
                            (array $of<ext.ext.ext.i32>ext
                                (null) 
                                (local.get $request)
                                (local.get $argument)
                                (local.get $argc)
                            )
                        )
                    )
        
                    (reflect $defineProperty<ext.ext.ext>
                        (self) 
                        (local.get $argument) 
                        (local.get $descriptor)
                    )

                    (reflect $apply<ext.ext.ext>
                        (ref.extern $setTimeout)
                        (null)
                        (array $of<ext>ext
                            (reflect $apply<ext.ext.ext>ext
                                (ref.extern $Function:bind)
                                (ref.extern $Reflect.deleteProperty)
                                (array $of<ext.ext.ext>ext 
                                    (null) 
                                    (self) 
                                    (local.get $argument)
                                )
                            )
                        )
                    )
                    
                    (br_if $bind_argument (local.get $argc))
                ) 
            )
        )

        (reflect $apply<ext.ext.ext>
            (ref.extern $setTimeout)
            (null)
            (array $of<ext>ext
                (reflect $apply<ext.ext.ext>ext
                    (ref.extern $Function:bind)
                    (local.get $handler)
                    (array $of<ext.ext>ext 
                        (null) (local.get $request)
                    )
                )
            )
        )

        (ref.extern $Infinity)
    )

    (global $values mut ext)

    (func $handle_argument
        (param $parameter       <String>)
        (param $cmd_offset           i32)
        (param $values       <Array>)
        (result             <Function>)
        (local $request       <String>)
        (local $argument       <String>)
        (local $value       <String>)

        (local.set $values (call $self.Object<ext>ext (local.get $values)))
        (local.set $values (array $from<ext>ext (local.get $values)))

        (if (reflect $get<ext.ext>i32 (local.get $values) (text "length"))
            (then
                (reflect $apply<ext.ext.ext>
                    (ref.extern $Array:push)
                    (global.get $values)
                    (local.get $values)
                )
            )
            (else
                (reflect $apply<ext.ext.ext>
                    (ref.extern $Array:push)
                    (global.get $values)
                    (array $of<ext>ext (local.get $parameter))
                )
            )
        )

        (console $log<ext.ext> (text "handle_argument parameter:") (this))
        (console $log<ext.i32> (text "handle_argument cmd_offset:") (local.get $cmd_offset))
        (console $log<ext.ext> (text "handle_argument values:") (local.get $values))
        (console $log<ext.ext> (text "global values:") (global.get $values))

        (object $defineProperty<ext.ext.ext>ext
            (reflect $apply<ext.fun.ext>ext
                (ref.extern $Function:bind)
                (ref.func $handle_argument)
                (array $of<ext.ext.i32>ext 
                    (null) 
                    (local.get $parameter) 
                    (local.get $cmd_offset)
                )
            )
            (ref.extern $Symbol.toPrimitive)
            (object $fromEntries<ext>ext
                (array $of<ext>ext
                    (array $of<ext.fun>ext 
                        (text "value")
                        (func $toPrimitive
                            (param $hint <String>)
                            (result     externref)
                            (warn (this))

                            (call $self.Number<i32>ext (i32.const 0))
                        )
                    )
                )
            )
        )
        (return)

        (reflect $set<ext.ext.i32> 
            (local.get $request) 
            (local.get $argument) 
            (true)
        )

        (reflect $apply<ext.fun.ext>ext
            (ref.extern $Function:bind)
            (func $arg_param
                (param $request     <Object>)
                (param $argument    <String>)
                (param $parameters   <Array>)
                (result           <Function>)

                (local.set $parameters 
                    (array $from<ext>ext 
                        (reflect $apply<ext.ext.ext>ext
                            (ref.extern $Array:flat)
                            (array $from<ext>ext (local.get $parameters))
                            (array)
                        )
                    )
                )

                (reflect $set<ext.ext.ext> 
                    (local.get $request) 
                    (local.get $argument) 
                    (local.get $parameters)
                )
            
                (reflect $apply<ext.ext.ext>ext
                    (ref.extern $Function:bind)
                    (ref.extern $Array:push)
                    (array $of<ext>ext (local.get $parameters))
                )
            )
            (array $of<ext.ext.ext>ext 
                (null) 
                (local.get $request)
                (local.get $argument)
            )
        )
    )

    (func $disable_argument
        (param $argument <String>)
        (reflect $deleteProperty<ext.ext> (self) (this))
    )

    (func $define_parameter
        (param $cmd_offset         i32)
        (param $parameter     <String>)
        (param $letter        <String>)
        (result                    i32)
        (local $index              i32)
        (local $descriptors   <Object>)

        (local.set $index (call $add_argument_count (this)))
        (local.set $descriptors (call $get_arguments (this)))

        (reflect $set<ext.ext.ext>
            (local.get $descriptors) 
            (local.get $parameter)
            (call $create_descriptor 
                (local.get $cmd_offset) 
                (local.get $parameter)
            )
        )

        (reflect $set<ext.ext.ext>
            (local.get $descriptors) 
            (local.get $letter)
            (call $create_descriptor 
                (local.get $cmd_offset) 
                (local.get $letter)
            )
        )

        (local.get $index)
    )

    (func $create_descriptor
        (param $offset             i32)
        (param $label         <String>)
        (result               <Object>)

        (object $fromEntries<ext>ext
            (array $of<ext.ext>ext
                (array $of<ext.i32>ext (text "configurable") (true))
                (array $of<ext.ext>ext (text "get") 
                    (reflect $apply<ext.fun.ext>ext
                        (ref.extern $Function:bind)
                        (ref.func $handle_argument)
                        (array $of<ext.ext.i32>ext 
                            (null) 
                            (reflect $apply<ext.ext.ext>ext
                                (ref.extern $String:concat)
                                (text "-")
                                (array $of<ext>ext (local.get $label))
                            )
                            (local.get $offset)
                        )
                    )
                )
            )
        )
    )

    (func $assign_cmd_offset
        (param $cmd           <String>)
        (param $offset             i32)
        (local $descriptor    <Object>)

        (local.set $descriptor (object))
        
        (reflect $set<ext.ext.i32> (local.get $descriptor) (text "configurable") (true))
        (reflect $set<ext.ext.ext> (local.get $descriptor) (text "get") 
            (reflect $apply<ext.fun.ext>ext
                (ref.extern $Function:bind)
                (ref.func $handle_request)
                (array $of<ext.i32>ext 
                    (null) 
                    (local.get $offset)
                )
            )
        )

        (reflect $defineProperty<ext.ext.ext> 
            (ref.extern $__proto__) 
            (local.get $cmd) 
            (local.get $descriptor)
        )
    )

    (func $register 
        (param $cmd           <String>)
        (param $handler        funcref)
        (result                    i32)
        (local $offset             i32)
        (local $getter      <Function>)

        (debug (local.get $cmd))    
        (debug "integration started..")

        (if (reflect $has<ext.ext>i32 (self) (local.get $cmd))
            (then (error "console command is in use.") unreachable)
        )

        (local.set $offset (call $new_offset))

        (call $set_cmd_index (local.get $offset) (call $add_ext (local.get $cmd)))
        (call $set_handler_index (local.get $offset) (call $add_ext (call $self.Object<fun>ext (local.get $handler))))
        (call $set_arguments_index (local.get $offset) (call $add_ext (object)))

        (call $assign_cmd_offset 
            (local.get $cmd) 
            (local.get $offset)
        )

        (local.get $offset)
    )
)