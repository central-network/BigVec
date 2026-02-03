(module
    (include "shared/memory.wat")

    (global $MODULE_OFFSET mut i32)
    (global $MODULE_LENGTH i32 i32(256))

    (global $TYPE_LOOP_HANDLER_EXIT_LOOP i32 i32(0))
    (global $TYPE_LOOP_HANDLER_SET_TIMEOUT i32 i32(1))
    (global $TYPE_LOOP_HANDLER_IDLE_CALLBACK i32 i32(2))
    (global $TYPE_LOOP_HANDLER_ANIMATION_FRAME i32 i32(3))
    (global $TYPE_LOOP_HANDLER_UNDEFINED i32 i32(4))

    (; OFFSET_LOOP_HANDLER = 4 ;)
    (func $set_loop_handler (param i32) (u8.store offset=4 (global.get $MODULE_OFFSET) (local.get 0)))
    (func $get_loop_handler (result i32) (u8.load offset=4 (global.get $MODULE_OFFSET)))
    
    (; OFFSET_LOOP_COUNT = 8 ;)
    (func $add_loop_count (result i32) (i32.atomic.rmw.add offset=8 (global.get $MODULE_OFFSET) i32(1)))
    (func $get_loop_count (result i32) (i32.atomic.load offset=8 (global.get $MODULE_OFFSET)))

    (; OFFSET_HANDLER_ID = 12 ;)
    (func $set_handler_id (param i32) (i32.store offset=12 (global.get $MODULE_OFFSET) (local.get 0)))
    (func $get_handler_id (result i32) (i32.load offset=12 (global.get $MODULE_OFFSET)))

    (; OFFSET_CURRENT_FRAME = 16 ;)
    (func $set_frame_count (param i32) (i32.store offset=16 (global.get $MODULE_OFFSET) (local.get 0)))
    (func $get_frame_count (result i32) (i32.load offset=16 (global.get $MODULE_OFFSET)))

    (global $OPTIONS_IDLE_CALLBACK mut ext)
    (global $TIMEOUT_IDLE_CALLBACK i32 i32(10000))
    (global $SET_TIMEOUT_DELAY i32 i32(50))

    (main $init

        (global.set $MODULE_OFFSET (call $malloc (global.get $MODULE_LENGTH)))
        (global.set $OPTIONS_IDLE_CALLBACK (object))

        (reflect $set<ext.ext.i32> 
            (global.get $OPTIONS_IDLE_CALLBACK) (text "timeout")
            (global.get $TIMEOUT_IDLE_CALLBACK)
        )

        (console $log<ext.i32> (text "MODULE_LENGTH") (global.get $MODULE_LENGTH))
        (console $log<ext.i32> (text "MODULE_OFFSET") (global.get $MODULE_OFFSET))

        (block $type
            (call $set_loop_handler (global.get $TYPE_LOOP_HANDLER_ANIMATION_FRAME))
            (br_if $type (reflect $has<ext.ext>i32 (self) (text "requestAnimationFrame")))

            (call $set_loop_handler (global.get $TYPE_LOOP_HANDLER_IDLE_CALLBACK))
            (br_if $type (reflect $has<ext.ext>i32 (self) (text "requestIdleCallback")))

            (call $set_loop_handler (global.get $TYPE_LOOP_HANDLER_SET_TIMEOUT))
            (br_if $type (reflect $has<ext.ext>i32 (self) (text "setTimeout")))

            (call $set_loop_handler (global.get $TYPE_LOOP_HANDLER_UNDEFINED))
        )

        (call $loop)
    )

    (func $exit
        (console $log<ext> (text "loop exit"))
    )

    (func $render
        (call $set_handler_id
            (reflect $apply<ext.ext.ext>i32
                (ref.extern $requestAnimationFrame)
                (self)
                (array $of<fun>ext (ref.func $onanimationframe))
            )
        )
    )

    (func $callback
        (call $set_handler_id
            (reflect $apply<ext.ext.ext>i32
                (ref.extern $requestIdleCallback)
                (self)
                (array $of<fun.ext>ext 
                    (ref.func $onidlecallback)
                    (global.get $OPTIONS_IDLE_CALLBACK)
                )
            )
        )
    )

    (func $timeout
        (call $set_handler_id
            (reflect $apply<ext.ext.ext>i32
                (ref.extern $setTimeout)
                (self)
                (array $of<fun.i32>ext 
                    (ref.func $ontimeout)
                    (global.get $SET_TIMEOUT_DELAY)
                )
            )
        )
    )

    (func $onanimationframe
        (param $epoch i32)
        (console $warn<ext> (text "render frame tick"))
        (call $ontick)
    )
    
    (func $onidlecallback
        (param $deadline <IdleDeadline>)
        (console $warn<ext> (text "idle callback tick"))
        (call $ontick)
    )
    
    (func $ontimeout
        (console $warn<ext> (text "set timeout tick"))
        (call $ontick)
    )
    
    (func $ontick
        (if (i32.lt_u (call $add_loop_count) i32(10))
            (then (call $loop))
        )
    )
    
    (func $loop
        (local $loop_handler i32)
        
        (local.set $loop_handler (call $get_loop_handler))

        (global.get $TYPE_LOOP_HANDLER_EXIT_LOOP)
        (if (i32.eq (local.get $loop_handler)) (then (call $exit) return))

        (global.get $TYPE_LOOP_HANDLER_ANIMATION_FRAME)
        (if (i32.eq (local.get $loop_handler)) (then (call $render) return))

        (global.get $TYPE_LOOP_HANDLER_IDLE_CALLBACK)
        (if (i32.eq (local.get $loop_handler)) (then (call $callback) return))

        (global.get $TYPE_LOOP_HANDLER_SET_TIMEOUT)
        (if (i32.eq (local.get $loop_handler)) (then (call $timeout) return))

        (unreachable)
    )
)(module
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
        (param $index             i32)
        (result                <Null>)

        (call $reset)

        (reflect $apply<ext.ext.ext> (table.get $externref (i32.add i32(1) (this))) (null) (self))
        (reflect $apply<ext.ext.ext> (table.get $externref (i32.add i32(2) (this))) (null) (self))
        (reflect $apply<ext.ext.ext> (table.get $externref (i32.add i32(3) (this))) (null) (self))

        (null)
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
)(module
    (include "shared/memory.wat")

    (global $MODULE_OFFSET mut i32)
    (global $MODULE_LENGTH i32 i32(256))

    (global $TYPE_LOOP_HANDLER_EXIT_LOOP i32 i32(0))
    (global $TYPE_LOOP_HANDLER_SET_TIMEOUT i32 i32(1))
    (global $TYPE_LOOP_HANDLER_IDLE_CALLBACK i32 i32(2))
    (global $TYPE_LOOP_HANDLER_ANIMATION_FRAME i32 i32(3))
    (global $TYPE_LOOP_HANDLER_UNDEFINED i32 i32(4))

    (; OFFSET_LOOP_HANDLER = 4 ;)
    (func $set_loop_handler (param i32) (u8.store offset=4 (global.get $MODULE_OFFSET) (local.get 0)))
    (func $get_loop_handler (result i32) (u8.load offset=4 (global.get $MODULE_OFFSET)))
    
    (; OFFSET_LOOP_COUNT = 8 ;)
    (func $add_loop_count (result i32) (i32.atomic.rmw.add offset=8 (global.get $MODULE_OFFSET) i32(1)))
    (func $get_loop_count (result i32) (i32.atomic.load offset=8 (global.get $MODULE_OFFSET)))

    (; OFFSET_HANDLER_ID = 12 ;)
    (func $set_handler_id (param i32) (i32.store offset=12 (global.get $MODULE_OFFSET) (local.get 0)))
    (func $get_handler_id (result i32) (i32.load offset=12 (global.get $MODULE_OFFSET)))

    (; OFFSET_CURRENT_FRAME = 16 ;)
    (func $set_frame_count (param i32) (i32.store offset=16 (global.get $MODULE_OFFSET) (local.get 0)))
    (func $get_frame_count (result i32) (i32.load offset=16 (global.get $MODULE_OFFSET)))

    (global $OPTIONS_IDLE_CALLBACK mut ext)
    (global $TIMEOUT_IDLE_CALLBACK i32 i32(10000))
    (global $SET_TIMEOUT_DELAY i32 i32(50))

    (main $init

        (global.set $MODULE_OFFSET (call $malloc (global.get $MODULE_LENGTH)))
        (global.set $OPTIONS_IDLE_CALLBACK (object))

        (reflect $set<ext.ext.i32> 
            (global.get $OPTIONS_IDLE_CALLBACK) (text "timeout")
            (global.get $TIMEOUT_IDLE_CALLBACK)
        )

        (console $log<ext.i32> (text "MODULE_LENGTH") (global.get $MODULE_LENGTH))
        (console $log<ext.i32> (text "MODULE_OFFSET") (global.get $MODULE_OFFSET))

        (block $type
            (call $set_loop_handler (global.get $TYPE_LOOP_HANDLER_ANIMATION_FRAME))
            (br_if $type (reflect $has<ext.ext>i32 (self) (text "requestAnimationFrame")))

            (call $set_loop_handler (global.get $TYPE_LOOP_HANDLER_IDLE_CALLBACK))
            (br_if $type (reflect $has<ext.ext>i32 (self) (text "requestIdleCallback")))

            (call $set_loop_handler (global.get $TYPE_LOOP_HANDLER_SET_TIMEOUT))
            (br_if $type (reflect $has<ext.ext>i32 (self) (text "setTimeout")))

            (call $set_loop_handler (global.get $TYPE_LOOP_HANDLER_UNDEFINED))
        )

        (call $loop)
    )

    (func $exit
        (console $log<ext> (text "loop exit"))
    )

    (func $render
        (call $set_handler_id
            (reflect $apply<ext.ext.ext>i32
                (ref.extern $requestAnimationFrame)
                (self)
                (array $of<fun>ext (ref.func $onanimationframe))
            )
        )
    )

    (func $callback
        (call $set_handler_id
            (reflect $apply<ext.ext.ext>i32
                (ref.extern $requestIdleCallback)
                (self)
                (array $of<fun.ext>ext 
                    (ref.func $onidlecallback)
                    (global.get $OPTIONS_IDLE_CALLBACK)
                )
            )
        )
    )

    (func $timeout
        (call $set_handler_id
            (reflect $apply<ext.ext.ext>i32
                (ref.extern $setTimeout)
                (self)
                (array $of<fun.i32>ext 
                    (ref.func $ontimeout)
                    (global.get $SET_TIMEOUT_DELAY)
                )
            )
        )
    )

    (func $onanimationframe
        (param $epoch i32)
        (console $warn<ext> (text "render frame tick"))
        (call $ontick)
    )
    
    (func $onidlecallback
        (param $deadline <IdleDeadline>)
        (console $warn<ext> (text "idle callback tick"))
        (call $ontick)
    )
    
    (func $ontimeout
        (console $warn<ext> (text "set timeout tick"))
        (call $ontick)
    )
    
    (func $ontick
        (if (i32.lt_u (call $add_loop_count) i32(10))
            (then (call $loop))
        )
    )
    
    (func $loop
        (local $loop_handler i32)
        
        (local.set $loop_handler (call $get_loop_handler))

        (global.get $TYPE_LOOP_HANDLER_EXIT_LOOP)
        (if (i32.eq (local.get $loop_handler)) (then (call $exit) return))

        (global.get $TYPE_LOOP_HANDLER_ANIMATION_FRAME)
        (if (i32.eq (local.get $loop_handler)) (then (call $render) return))

        (global.get $TYPE_LOOP_HANDLER_IDLE_CALLBACK)
        (if (i32.eq (local.get $loop_handler)) (then (call $callback) return))

        (global.get $TYPE_LOOP_HANDLER_SET_TIMEOUT)
        (if (i32.eq (local.get $loop_handler)) (then (call $timeout) return))

        (unreachable)
    )
)(module
    (import "self" "global" (table $global 1 65536 externref))

    (include "shared/global.wat")

    (main $set_globals
        (;
            set global to table.global index
            get from table with this index
            and set global from external value

            something like that... 💞
        ;)
    )
)(module
    (include "shared/memory.wat")
    (include "shared/imports.wat")

    (global $idbase           mut ext)
    (global $onopen           mut ext)
    (global $config           mut ext)
    (global $version          mut i32)
    (global $database         mut ext)
    (global $storename        mut ext)

    (main $idb
        (wasm.export (ref.module $idb) (ref.func $open))
        (wasm.export (ref.module $idb) (ref.func $del))
        (wasm.export (ref.module $idb) (ref.func $get))
        (wasm.export (ref.module $idb) (ref.func $set))
        (wasm.export (ref.module $idb) (ref.func $has))
        (wasm.export (ref.module $idb) (ref.func $count))
        (wasm.export (ref.module $idb) (ref.func $version))
    )

    (func $open
        (param $dbname       <String>)
        (param $storename    <String>)
        (param $version           i32)
        (result             <Promise>)

        (global.set $storename  
            (if (result externref) 
                (ref.is_null (local.get $storename))
                (then (local.get $dbname))
                (else (local.get $storename))
            )
        )

        (global.set $version
            (select 
                (local.get $version) 
                (true) 
                (local.get $version)
            )
        )

        (call $get_delayer)

        (call $IDBFactory:open 
            (local.get $dbname)
            (global.get $version)
            (func $onneedupgrade
                (param $event <IDBVersionChangeEvent>)

                (global.set $database 
                    (call $IDBRequest:result
                        (call $Event:target (this))
                    )
                )
                
                (call $IDBDatabase:createObjectStore 
                    (global.get $database) 
                    (global.get $storename) 
                )
            ) 
            (func $onopensucceed
                (param $event <IDBOpenDBSuccessEvent>)

                (global.set $database 
                    (call $IDBRequest:result
                        (call $Event:target (this))
                    )
                )

                (reflect $apply<ext.ext.ext> 
                    (global.get $onopen) 
                    (global.get $idbase) 
                    (array $of<ext>ext 
                        (global.get $database)
                    )
                )
            )
        )
    )

    (func $get
        (param $key                 <String>)
        (result                    <Promise>)

        (async.ext 
            (call $get_reader (this))
            (then $onidbreader 
                (param $items          <Array>)
                (result              <Promise>)

                (call $IDBObjectStore:get 
                    (reflect $get<ext.i32>ext (this) i32(1))
                    (reflect $get<ext.i32>ext (this) i32(2))
                )
            )
        )
    )
    
    (func $has
        (param $key          <String|Number>)
        (result                    <Promise>)

        (async.ext 
            (call $get_reader (this))
            (then $onidbreader 
                (param $items          <Array>)
                (result              <Promise>)

                (call $IDBObjectStore:getKey 
                    (reflect $get<ext.i32>ext (this) i32(1))
                    (reflect $get<ext.i32>ext (this) i32(2))
                )
            )
        )
    )

    (func $set
        (param $key       <String|Number>)
        (param $value           externref)
        (result                 <Promise>)

        (async.ext 
            (call $get_writer (this) (local.get $value))
            (then $onidbwriter 
                (param $items               <Array>)
                (result                   <Promise>)

                (call $IDBObjectStore:put 
                    (reflect $get<ext.i32>ext (this) i32(1))
                    (reflect $get<ext.i32>ext (this) i32(3))
                    (reflect $get<ext.i32>ext (this) i32(2))
                )
            )
        )
    )

    (func $count
        (result <Promise>)

        (async.ext 
            (call $get_reader (null))
            (then $onreader
                (param $items          <Array>)
                (result              <Promise>)

                (call $IDBObjectStore:count
                    (reflect $get<ext.i32>ext (this) i32(1))
                )
            )
        )
    )

    (func $del
        (param $key          <String|Number>)
        (result                    <Promise>)

        (async.ext 
            (call $get_writer (this) (null))
            (then $onidbwriter 
                (param $items          <Array>)
                (result              <Promise>)

                (call $IDBObjectStore:delete 
                    (reflect $get<ext.i32>ext (this) i32(1))
                    (reflect $get<ext.i32>ext (this) i32(2))
                )
            )
        )
    )

    (func $version
        (result i32)
        (global.get $version)
    )

    (func $get_delayer
        (result              <Promise>)
        (local $withResolvers <Object>)
        
        (if (ref.is_null (global.get $idbase))
            (then
                (local.set $withResolvers
                    (reflect $apply<ext.ext.ext>ext
                        (ref.extern $Promise.withResolvers)
                        (ref.extern $Promise)
                        (array)
                    )
                )

                (global.set $idbase (reflect $get<ext.ext>ext (local.get $withResolvers) (text "promise")))
                (global.set $onopen (reflect $get<ext.ext>ext (local.get $withResolvers) (text "resolve")))
            )
        )

        (global.get $idbase)
    )

    (func $get_writer
        (param $key      <String|Number>)
        (param $value          externref)
        (result                <Promise>)
        
        (array $fromAsync<ext>ext
            (array $of<ext.ext.ext.ext>ext 
                (call $get_delayer)
                (call $IDBTransaction:objectStore 
                    (call $IDBDatabase:transaction 
                        (global.get $database) 
                        (global.get $storename) 
                        (text "readwrite")
                    )
                    (global.get $storename)
                )
                (local.get $key) 
                (local.get $value) 
            )
        )
    )

    (func $get_reader
        (param $key      <String|Number>)
        (result                <Promise>)

        (array $fromAsync<ext>ext 
            (array $of<ext.ext.ext>ext 
                (call $get_delayer)
                (call $IDBTransaction:objectStore 
                    (call $IDBDatabase:transaction 
                        (global.get $database) 
                        (global.get $storename) 
                        (text "readonly")
                    )
                    (global.get $storename)
                )
                (local.get $key) 
            )
        )
    )

    (func $IDBObjectStore:keys
        (param $store       <IDBObjectStore>)
        (result                    externref)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:getAllKeys)
                (this)
                (array)
            )
        )
    )

    (func $IDBDatabase:transaction
        (param $idb            <IDBDatabase>)
        (param $name                <String>)
        (param $mode                <String>)
        (result             <IDBTransaction>)
        
        (reflect $apply<ext.ext.ext>ext
            (ref.extern $IDBDatabase:transaction)
            (this)
            (array $of<ext.ext>ext
                (local.get $name)
                (local.get $mode)
            )
        )
    )

    (func $IDBTransaction:objectStore
        (param $transaction <IDBTransaction>)
        (param $name                <String>)
        (result             <IDBObjectStore>)
        
        (reflect $apply<ext.ext.ext>ext
            (ref.extern $IDBTransaction:objectStore)
            (this)
            (array $of<ext>ext (local.get $name))
        )
    )

    (func $IDBFactory:open
        (param $name                <String>)
        (param $version                  i32)
        (param $upgradehandler       funcref)
        (param $successhandler       funcref)
        (local $openreq   <IDBOpenDBRequest>)

        (local.set $openreq
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBFactory:open)
                (ref.extern $indexedDB)
                (array $of<ext.i32>ext 
                    (local.get $name)
                    (local.get $version)
                )
            )
        )

        (if (i32.eqz (ref.is_null (local.get $upgradehandler)))
            (then
                (reflect $apply<ext.ext.ext>
                    (ref.extern $EventTarget:addEventListener)
                    (local.get $openreq)
                    (array $of<ext.fun>ext 
                        (text "upgradeneeded") 
                        (local.get $upgradehandler)
                    )
                )
            )
        )

        (if (i32.eqz (ref.is_null (local.get $successhandler)))
            (then
                (reflect $apply<ext.ext.ext>
                    (ref.extern $EventTarget:addEventListener)
                    (local.get $openreq)
                    (array $of<ext.fun>ext 
                        (text "success") 
                        (local.get $successhandler)
                    )
                )
            )
        )
    )

    (func $IDBObjectStore:remove
        (param $store       <IDBObjectStore>)
        (param $index                    i32)
        (result                    <Promise>)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:delete)
                (this)
                (array $of<i32>ext (local.get $index))
            )
        )
    )

    (func $IDBObjectStore:count
        (param $store       <IDBObjectStore>)
        (result                    <Promise>)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:count)
                (this)
                (array)
            )
        )
    )

    (func $IDBObjectStore:delete
        (param $store       <IDBObjectStore>)
        (param $key                 <String>)
        (result                    <Promise>)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:delete)
                (this)
                (array $of<ext>ext (local.get $key))
            )
        )
    )

    (func $IDBObjectStore:get
        (param $store       <IDBObjectStore>)
        (param $key                 <String>)
        (result                    <Promise>)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:get)
                (this)
                (array $of<ext>ext 
                    (local.get $key)
                )
            )
        )
    )

    (func $IDBObjectStore:at
        (param $store       <IDBObjectStore>)
        (param $index                    i32)
        (result                    <Promise>)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:get)
                (this)
                (array $of<i32>ext 
                    (local.get $index)
                )
            )
        )
    )

    (func $IDBObjectStore:getIndex
        (param $store       <IDBObjectStore>)
        (param $index                    i32)
        (result                    <Promise>)

        (async.ext
            (array $fromAsync<ext>ext
                (array $of<i32.ext>ext
                    (local.get $index) 
                    (call $async_request
                        (reflect $apply<ext.ext.ext>ext
                            (ref.extern $IDBObjectStore:getKey)
                            (this)
                            (array $of<i32>ext (local.get $index))
                        )
                    )
                )
            )
            (then $ongetkeydone
                (param $async <Array>)
                (result i32)
                (i32.eq 
                    (reflect $get<ext.i32>i32 (this) i32(0))
                    (reflect $get<ext.i32>i32 (this) i32(1))
                )
            )
        )
    )

    (func $IDBObjectStore:getKey
        (param $store       <IDBObjectStore>)
        (param $key                 <String>)
        (result                    <Promise>)

        (async.ext
            (array $fromAsync<ext>ext
                (array $of<ext.ext>ext
                    (local.get $key) 
                    (call $async_request
                        (reflect $apply<ext.ext.ext>ext
                            (ref.extern $IDBObjectStore:getKey)
                            (this)
                            (array $of<ext>ext (local.get $key))
                        )
                    )
                )
            )
            (then $ongetkeydone
                (param $async <Array>)
                (result i32)
                (object $is<ext.ext>i32 
                    (reflect $get<ext.i32>ext (this) i32(0))
                    (reflect $get<ext.i32>ext (this) i32(1))
                )
            )
        )
    )

    (func $IDBObjectStore:set
        (param $store       <IDBObjectStore>)
        (param $value              externref)
        (param $index                    i32)
        (result                    <Promise>)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:put)
                (this)
                (array $of<ext.i32>ext 
                    (local.get $value) 
                    (local.get $index)
                )
            )
        )
    )

    (func $IDBObjectStore:put
        (param $store       <IDBObjectStore>)
        (param $value              externref)
        (param $key                 <String>)
        (result                    <Promise>)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:put)
                (this)
                (array $of<ext.ext>ext 
                    (local.get $value) 
                    (local.get $key)
                )
            )
        )
    )

    (func $IDBDatabase:createObjectStore
        (param $database       <IDBDatabase>)
        (param $name                <String>)

        (reflect $apply<ext.ext.ext>
            (ref.extern $IDBDatabase:createObjectStore)
            (local.get $database)
            (array $of<ext>ext (local.get $name))
        )
    )

    (func $IDBRequest:result
        (param $request         <IDBRequest>)
        (result                    <Promise>)    

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $IDBRequest:result[get])
            (this)
            (array)
        )
    )
    
    (func $Event:target
        (param $event                <Event>)
        (result                    externref)    

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $Event:target[get])
            (this)
            (array)
        )
    )

    (func $async_request
        (param $request         <IDBRequest>)
        (result                    <Promise>)
        (local $withResolvers       <Object>)

        (local.set $withResolvers 
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $Promise.withResolvers)
                (ref.extern $Promise)
                (array)
            )
        )

        (reflect $apply<ext.ext.ext>
            (ref.extern $IDBRequest:onsuccess[set])
            (local.get $request)
            (array $of<ext>ext 
                (reflect $get<ext.ext>ext 
                    (local.get $withResolvers) 
                    (text "resolve")
                )
            )
        )

        (reflect $apply<ext.ext.ext>
            (ref.extern $IDBRequest:onerror[set])
            (local.get $request)
            (array $of<ext>ext 
                (reflect $get<ext.ext>ext 
                    (local.get $withResolvers) 
                    (text "reject")
                )
            )
        )

        (async.ext
            (reflect $get<ext.ext>ext 
                (local.get $withResolvers) 
                (text "promise")
            )
            (then $onopensuccess 
                (param $event              <Event>)
                (result         <IDBOpenDBRequest>)
                (call $Event:target (this))
            )
            (then $oneventtarget
                (param $request       <IDBRequest>)
                (result              <IDBDatabase>)
                (call $IDBRequest:result (this))
            )
        )
    )
)(module
    (memory $memory 1 65536 shared)
    (table  $funcref 1 65536 funcref)
    (table  $externref 1 65536 externref)

    (data (i32.const 4) "\10")

    (export "#memory" (memory $memory))
    (export "#funcref" (table $funcref))
    (export "#externref" (table $externref))
)(module

    (func $start
        (param $app                             i32)
        (result                                 i32)
        (local $pid                             i32)

        (local.set $pid 
            (table.grow $process 
                (call $resolve 
                    (table.get $module 
                        (local.get $app)
                    )
                )
                (true)
            )
        )

        (async 
            (array $fromAsync<ext>ext
                (array $of<ext.i32>ext
                    (table.get $process (local.get $pid))
                    (local.get $pid)
                )
            )
            (then $onmodule
                (param $items              <Array>)
                (result                  <Promise>)
                (local $module            <Module>)
                (local $instantination   <Promise>)
                (local $index                  i32)

                (local.set $module (reflect $get<ext.i32>ext (this) i32(0)))
                (local.set $index (reflect $get<ext.i32>i32 (this) i32(1)))

                (table.set $process 
                    (local.get $index)
                    (call $instantiate (local.get $module))
                )

                (reflect $set<ext.i32.ext> 
                    (local.get $items) 
                    (i32.const 0) 
                    (table.get $process (local.get $index))
                )

                (array $fromAsync<ext>ext (this))
            )
            (then $oninstantiate
                (param $items             <Array>)
                (local $instance       <Instance>)
                (local $index                 i32)

                (local.set $instance (reflect $get<ext.i32>ext (this) i32(0)))
                (local.set $index (reflect $get<ext.i32>i32 (this) i32(1)))
                
                (table.set $process 
                    (local.get $index) 
                    (local.get $instance)
                )
            )
        )

        (local.get $pid)
    )

    (func $install
        (param $url                       <String>)
        (result                                i32)
        (local $index                          i32)
        (local $fetch                    <Request>)

        (local.set $fetch
            (call $fetch (local.get $url))
        )
        
        (local.set $index 
            (table.grow $module
                (local.get $fetch) 
                (true)
            )
        )

        (async 
            (array $fromAsync<ext>ext
                (array $of<i32.ext>ext
                    (local.get $index)
                    (local.get $fetch)
                )
            )
            (then $onbuffer
                (param $items              <Array>)
                (result                  <Promise>)

                (reflect $set<ext.i32.ext> 
                    (this)
                    (i32.const 2)
                    (reflect $apply<ext.ext.ext>ext 
                        (reflect $get<ext.ext>ext (global.get $idb) (text "set"))
                        (null)
                        (local.get $items)
                    )
                )

                (array $fromAsync<ext>ext (this))
            )
            (then $onpersist
                (param $items              <Array>)
                (result                  <Promise>)

                (reflect $set<ext.i32.ext> 
                    (this)
                    (i32.const 1)
                    (call $compile (reflect $get<ext.i32>ext (this) i32(1)))
                )

                (array $fromAsync<ext>ext (this))
            )
            (then $onmodule
                (param $items             <Array>)
                (local $module           <Module>)
                (local $index                 i32)

                (local.set $index (reflect $get<ext.i32>i32 (this) i32(0)))
                (local.set $module (reflect $get<ext.i32>ext (this) i32(1)))

                (table.set $module 
                    (local.get $index) 
                    (local.get $module)
                )
            )
        )

        (local.get $index)
    )

    (func $resolve
        (param $any                       <Object>)
        (result                          <Promise>)

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $Promise.resolve)
            (ref.extern $Promise)
            (array $of<ext>ext (this))
        )
    )   

    (func $compile
        (param $source                    <Buffer>)
        (result                          <Promise>)

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $WebAssembly.compile)
            (ref.extern $WebAssembly)
            (array $of<ext>ext (this))
        )
    )   

    (func $instantiate
        (param $module                    <Module>)
        (result                          <Promise>)

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $WebAssembly.instantiate)
            (ref.extern $WebAssembly)
            (array $of<ext.ext>ext (this) (self))
        )
    )   

    (func $fetch
        (param $target                    <String>)
        (result                          <Promise>)

        (async.ext
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $fetch)
                (self)
                (array $of<ext>ext (this))
            )
            (then $onresponse
                (param $response        <Response>)
                (result              <ArrayBuffer>)

                (reflect $apply<ext.ext.ext>ext
                    (ref.extern $Response:arrayBuffer)
                    (this)
                    (array)
                )
            )
        )
    )
)(module $mt
    (include "shared/memory.wat")
    (include "shared/imports.wat")
    (include "shared/worker.wat")

    (data $worker.js "file://worker.js")
    (data $mt_self "wasm://mt_self.wat")
    (data $mt_agent "wasm://mt_agent.wat")
    (data $mt_console "wasm://bind_console/mt.wat")
    (data $console "file://../wasm/console.wasm")

    (global $module.console mut i32)
    (global $module.mt_self mut i32)
    (global $module.mt_agent mut i32)
    (global $module.mt_console mut i32)

    (global $MODULE_OFFSET mut i32)
    (global $MODULE_LENGTH i32 i32(64))

    (main $portal
        (apply $Performance:now<ext>f32
            (self $performance<ext>)
        )

        (apply $Promise:then
            (param externref externref)
            (result externref)
            (self)
            (array $of<fun>ext 
                (apply $navigator.gpu<ext>ext
                    (self $navigator)
                )
            )
        )

        (apply $Promise:catch
            (param externref externref)
            (result externref)
            (self)
            (array $of<fun>ext 
                (apply $navigator.gpu<ext>ext
                    (self $navigator)
                )
            )
        )

        (apply $WebAssembly.Memory:buffer[get]
            (param)
            (result externref)
            (self)
            (array)
        )

        (set.extern (self) (text "wasm") (wasm))
        (async
            (array $fromAsync<ext>ext
                (array $of<ext.ext.ext.ext>ext
                    (wasm.compile (data.view $console))
                    (wasm.compile (data.view $mt_self))
                    (wasm.compile (data.view $mt_agent))
                    (wasm.compile (data.view $mt_console))
                )
            )
            (then $oncompile
                (param $items    <Array>)
                (result        <Promise>)
                (local $module  <Module>)

                (local.tee $module (get.i32_extern (this) i32(1)))
                (global.set $module.mt_self (table.add $externref (true)))
                (wasm.set_i32 "module.mt_self" (global.get $module.mt_self))

                (local.tee $module (get.i32_extern (this) i32(2)))
                (global.set $module.mt_agent (table.add $externref (true)))
                (wasm.set_i32 "module.mt_agent" (global.get $module.mt_agent))

                (local.tee $module (get.i32_extern (this) i32(3)))
                (global.set $module.mt_console (table.add $externref (true)))
                (wasm.set_i32 "module.mt_console" (global.get $module.mt_console))

                (local.tee $module (get.i32_extern (this) i32(0)))
                (global.set $module.console (table.add $externref (true)))
                (wasm.set_i32 "module.console" (global.get $module.console))

                (wasm.instantiate (local.get $module))
            ) 
            (then $onconsolemodule
                (call $main)
            )
        )
    )

    (func $main
        (local $module  <Module>)
        (global.set $MODULE_OFFSET (malloc (global.get $MODULE_LENGTH)))

        (wasm.export (ref.module $mt) (ref.func $fork))
        (wasm.export (ref.module $mt) (ref.func $ref))
        (wasm.export (ref.module $mt) (ref.func $close))

        (local.set $module (table.get $externref (global.get $module.mt_console)))
        (wasm.instantiate (local.get $module))
        (drop)
    )

    (func $fork
        (param $count           i32)
        (result                 i32)
        (local $instance <Instance>)
        (local $index           i32)

        (async
            (wasm.instantiate $module.mt_self)
            (then $oninstance
                (param $instance <Instance>)
                (warn (this))
            )
        )
        (true)
    )

    (func $close
        (param $index        i32)
    )

    (func $ref
        (param $index        i32)
        (result         <Worker>)

        (null)
    )

)(module
    (include "shared/memory.wat")
    (include "shared/worker.wat")

    (import "wasm" "offset" (global $MODULE_OFFSET i32))
    (import "wasm" "length" (global $MODULE_LENGTH i32))

    (main $worker_thread
        (call $set_current_status (global.get $WORKER_STATUS_READY))
        (call $bind_scope)
        (call $mutex_loop)
        (call $set_current_status (global.get $WORKER_STATUS_CLOSED))
    )

    (func $mutex_loop
        (block $close
            (loop $while
                (call $lock_mutex) 
                (debug "mutex unlocked")

                (console $error<i32> (call $get_mutex_value))

                (br_if $close (call $has_sigint))
                (br_if $while (call $has_notify))
            )

            (call $self.postMessage<i32> (global.get $WORKER_EVENT_CODE_CLOSE))
            (call $self.close<>)
        )
    )

    (func $bind_scope
        (set.extern (self) (text "onerror") (ref.extern $close))
        (set.extern (self) (text "onunhandledrejection") (ref.extern $close))
    )
)(module
    (include "shared/memory.wat")
    (include "shared/imports.wat")
    (include "shared/worker.wat")

    (data $worker.js "file://worker.js")
    (data $agent.wasm "wasm://mt_agent.wat")
    (data $mt_console.wasm "wasm://bind_console/mt.wat")

    (global $MODULE_OFFSET mut i32)
    (global $MODULE_LENGTH i32 i32(256))

    (main $mt
        (debug "hello from mt")
        (global.set $MODULE_OFFSET (malloc (global.get $MODULE_LENGTH)))

        (call $reset_status)
        (call $reset_mutex)
        (call $clear_sigint)

        (table.add $funcref (ref.func $create) (true)) (console $log<i32>)
        (table.add $funcref (ref.func $close) (true)) (console $log<i32>)
        (table.add $funcref (ref.func $terminate) (true)) (console $log<i32>)
        (table.add $funcref (ref.func $get_process) (true)) (console $log<i32>)

        (async
            (wasm.compile (data.view $agent.wasm))
            (then $onagentmodule
                (param $module.wasm         <Module>)
                (local $data                <Object>)
                (local $module              <Object>)

                (local.set $data (object))
                (local.set $module (object))

                (set.extern     (local.get $module) (text "#memory") (global.get $memory))
                (set.extern     (local.get $module) (text "module") (local.get $module.wasm))
                (set.extern_i32 (local.get $module) (text "offset") (global.get $MODULE_OFFSET))
                (set.extern_i32 (local.get $module) (text "length") (global.get $MODULE_LENGTH))

                (set.extern (local.get $data) (text "wasm") (local.get $module))

                (call $set_data_extern_index (call $add_externref (local.get $data)))
            )
            (then $onagentdata
                (call $create)
                (call $instantiate)
            )
        )
    )

    (func $add_externref
        (param $any       externref)
        (result                 i32)
        (table.add $externref (this) (true))
    )

    (func $remove_extern
        (param $index           i32)
        (table.set $externref (this) (null))
    )

    (func $get_process
        (result            <Worker>)
        (table.get $externref (call $get_process_extern_index))
    )

    (func $get_data
        (result            <Worker>)
        (table.get $externref (call $get_data_extern_index))
    )

    (func $new_process
        (result <Worker>)
        
        (reflect $construct<ext.ext>ext 
            (ref.extern $Worker) 
            (array $of<ext>ext (data.url $worker.js))
        )
    )

    (func $performance.now
        (result i32)
        
        (reflect $apply<ext.ext.ext>i32 
            (ref.extern $Performance:now) 
            (ref.extern $performance) 
            (array)
        )
    )

    (func $listen
        (reflect $apply<ext.ext.ext>
            (ref.extern $Worker:onmessage[set]) 
            (call $get_process) 
            (array $of<fun>ext (ref.func $onmessage))
        )
    )

    (func $onmessage
        (param $event <Event>)
        (local $code      i32)

        (local.tee $code (get.data_i32 (this)))
        (if (i32.eq (global.get $WORKER_EVENT_CODE_CLOSE))
            (then 
                (debug "Worker before close message came..")
                (call $terminate)
                (call $set_current_status (global.get $WORKER_STATUS_CLOSED))
            )
        )
    )

    (func $create
        (local $worker_thread   <Worker>)
        (local $extern_index         i32)
        (call $set_current_status (global.get $WORKER_STATUS_CREATE_BEGIN))

        (local.set $worker_thread (call $new_process))
        (local.set $extern_index  (call $add_externref (this)))

        (call $set_process_extern_index (local.get $extern_index))
        (call $set_new_worker_time (call $performance.now))
        (call $listen)

        (call $set_current_status (global.get $WORKER_STATUS_CREATE_END))
    )

    (func $instantiate
        (reflect $apply<ext.ext.ext> 
            (ref.extern $Worker:postMessage) 
            (call $get_process)
            (array $of<ext>ext (call $get_data))
        )
    )

    (func $close
        (call $set_current_status (global.get $WORKER_STATUS_CLOSING))
        (call $mark_sigint)
        (call $unlock_mutex)
    )

    (func $terminate
        (call $set_current_status (global.get $WORKER_STATUS_TERMINATE_BEGIN))

        (reflect $apply<ext.ext.ext> 
            (ref.extern $Worker:terminate) 
            (call $get_process)
            (array)
        )

        (call $remove_extern (call $get_process_extern_index))
        (call $reset_process_extern_index)
        (call $set_current_status (global.get $WORKER_STATUS_TERMINATE_END))
    )
)(module 
    (data $idb.wasm "file://../wasm/idb.wasm")
    (data $uuid.wasm "file://../wasm/uuid.wasm")
    (data $import.wasm "file://../wasm/import.wasm")
    (data $console.wasm "file://../wasm/console.wasm")

    (data $idb_console.wasm "file://../wasm/idb_console.wasm")
    (data $uuid_console.wasm "file://../wasm/uuid_console.wasm")

    (global $wasm new Object)

    (global $idb.wasm mut ext)
    (global $uuid.wasm mut ext)
    (global $import.wasm mut ext)
    (global $console.wasm mut ext)

    (main $portal
        (set.extern (self) (text "wasm") (wasm))

        (async 
            (array $fromAsync<ext>ext
                (array $of<ext.ext.ext.ext.ext>ext
                    (wasm.compile (data.view $idb.wasm))
                    (wasm.compile (data.view $idb_console.wasm))
                    (wasm.compile (data.view $uuid.wasm))
                    (wasm.compile (data.view $import.wasm))
                    (wasm.compile (data.view $console.wasm))
                )
            )
            (then $onallmodulecompile
                (param $module/s             <Array>)
                (result                    <Promise>)

                (global.set $idb.wasm (get.i32_extern (this) i32(0)))
                (global.set $uuid.wasm (get.i32_extern (this) i32(1)))
                (global.set $import.wasm (get.i32_extern (this) i32(2)))
                (global.set $console.wasm (get.i32_extern (this) i32(3)))

                (wasm.instantiate (global.get $import.wasm) (self))
            )
            (then $onimportinstance
                (param $instance    <Object|Instance>)
                (result                     <Promise>)

                (call $assign (wasm.exports (this)))

                (drop (call $extref (self)))
                (drop (call $extref (wasm)))

                (call $define (text "module.idb") (global.get $idb.wasm))
                (call $define (text "module.uuid") (global.get $uuid.wasm))
                (call $define (text "module.import") (global.get $import.wasm))
                (call $define (text "module.console") (global.get $console.wasm))

                (wasm.instantiate (global.get $console.wasm) (self))
            )
            (then $onconsoleinstance
                (param $instance           <Instance>)
                (result                     <Promise>)

                (console $warn<ext.ext> (text "console started") (this))
                (wasm.instantiate (global.get $idb.wasm) (self))
            )
            (then $onidbinstance
                (param $instance           <Instance>)
                (result                     <Promise>)

                (console $warn<ext.ext> (text "idb started") (this))
                (wasm.instantiate (global.get $uuid.wasm) (self))
            )
            (then $onuuidinstance
                (param $instance           <Instance>)

                (console $warn<ext.ext> (text "uuid started") (this))
            )
        )
    )

    (func $assign
        (param $value      <Object>)

        (reflect $apply<ext.ext.ext> 
            (ref.extern $Object.assign)
            (ref.extern $Object)
            (array $of<ext.ext>ext (wasm) (this))
        )
    )

    (func $define
        (param $key        <String>)
        (param $value     externref)

        (reflect $set<ext.ext.i32> 
            (wasm) 
            (local.get $key)
            (call $extref (local.get $value))
        )
    )

    (func $extref
        (param $key        <String>)
        (result                 i32)

        (reflect $apply<ext.ext.ext>i32 
            (ref.extern $WebAssembly.Table:grow) 
            (get.extern (wasm) (text "#externref"))
            (array $of<i32.ext>ext (true) (this))
        )
    )
)(module
    (include "shared/imports.wat")
    (include "call_indirect/idb.wat")
    
    (memory $base {{PAGE_COUNT}})

    (global $MAX_COUNT   mut i32)
    (global $UUID_COUNT  mut i32)
    (global $BLOCK_COUNT mut i32)

    (global $ARGUMENTS_REGEXP_CLEAR_STR mut ext)
    (global $ARGUMENTS_REGEXP_MATCH_HEX mut ext)

    (global $stride (mut v128) (v128.const i32x4 0 0 0 0))

    (main $init
        (local $offset i32)

        (memory.size)
        (i32.mul (i32.const 65536))
        (i32.div_u (i32.const 16))
        (global.set $MAX_COUNT)
        (global.set $BLOCK_COUNT i32(1))

        (global.set $ARGUMENTS_REGEXP_CLEAR_STR (call $regexp_args_array (text "[^a-f0-9]") (string)))
        (global.set $ARGUMENTS_REGEXP_MATCH_HEX (call $regexp_args_array (text "(..)") (string)))

        (global.set $stride (call $calc_stride (memory.size)))

        (wasm.export (ref.module $uuid) (ref.func $indexOf))
        (wasm.export (ref.module $uuid) (ref.func $has))
        (wasm.export (ref.module $uuid) (ref.func $count))
        (wasm.export (ref.module $uuid) (ref.func $forEach))
        (wasm.export (ref.module $uuid) (ref.func $push))
        (wasm.export (ref.module $uuid) (ref.func $at))
    )


    (func $forEach
        (param $callback externref)
        (param $thisArg  externref)
        (local $iterator      v128)
        (local $iterated      v128)

        (local.set $iterator (v128.const i32x4 -1 4 1 0))
        (local.set $iterated (i32x4.replace_lane 0 (local.get $iterated) (global.get $UUID_COUNT)))

        (loop $iteration
            (if (i32x4.extract_lane 0 (local.get $iterated))
                (then
                    (reflect $apply<ext.ext.ext>
                        (local.get $callback)
                        (local.get $thisArg)
                        (array $of<ext.i32>ext
                            (call $at (i32x4.extract_lane 2 (local.get $iterated)))
                            (i32x4.extract_lane 2 (local.get $iterated))
                        )
                    )

                    (local.set $iterated
                        (i32x4.add (local.get $iterated) (local.get $iterator))
                    )
                    
                    (br $iteration)
                )
            )
        )
    )

    (func $count 
        (result i32) 
        (global.get $UUID_COUNT)
    )

    (func $has              
        (param $string  ext) 
        (result         i32) 
        
        (if (i32.ne 
                (i32.const -1) 
                (call $find (call $parse_uuid_vector (local.get $string)))
            )
            (then (return (i32.const 1)))
        )

        (i32.const 0)
    )

    (func $indexOf
        (param $string externref)
        (result i32)

        (call $find (call $parse_uuid_vector (local.get $string)))
    )

    (func $push
        (param $string externref)
        (result i32)
        (local $index i32)

        (call $set_index_vector
            (local.tee $index (call $next_vector_index))
            (call $parse_uuid_vector (local.get $string))
        )

        (local.get $index)    
    )
    
    (func $at
        (param $index i32)
        (result externref)

        (local $offset v128)
        (local $offset.i8b i32)
        (local $offset.i16 i32)
        (local $offset.i32 i32)
        (local $offset.i64 i32)

        (if (i32.lt_s (local.get $index) (i32.const 0))
            (then (local.set $index (i32.add (global.get $UUID_COUNT) (local.get $index))))
        )

        (v128.const i32x4 1 2 4 8) 
        (i32x4.mul (i32x4.splat (local.get $index)))
        (i32x4.add (global.get $stride))
        (local.set $offset)

        (local.set $offset.i8b (i32x4.extract_lane 0 (local.get $offset)))
        (local.set $offset.i16 (i32x4.extract_lane 1 (local.get $offset)))
        (local.set $offset.i32 (i32x4.extract_lane 2 (local.get $offset)))
        (local.set $offset.i64 (i32x4.extract_lane 3 (local.get $offset)))        

        (string)
        (call $num_concat (i32.load8_u offset=7 (local.get $offset.i64)))
        (call $num_concat (i32.load8_u offset=6 (local.get $offset.i64)))
        (call $num_concat (i32.load8_u offset=5 (local.get $offset.i64)))
        (call $num_concat (i32.load8_u offset=4 (local.get $offset.i64)))
        (call $num_concat (i32.load8_u offset=3 (local.get $offset.i64)))
        (call $num_concat (i32.load8_u offset=2 (local.get $offset.i64)))
        (call $str_concat (text "-"))
        (call $num_concat (i32.load8_u offset=1 (local.get $offset.i64)))
        (call $num_concat (i32.load8_u offset=0 (local.get $offset.i64)))
        (call $str_concat (text "-"))
        (call $num_concat (i32.load8_u offset=3 (local.get $offset.i32)))
        (call $num_concat (i32.load8_u offset=2 (local.get $offset.i32)))
        (call $str_concat (text "-"))
        (call $num_concat (i32.load8_u offset=1 (local.get $offset.i32)))
        (call $num_concat (i32.load8_u offset=0 (local.get $offset.i32)))
        (call $str_concat (text "-"))
        (call $num_concat (i32.load8_u offset=1 (local.get $offset.i16)))
        (call $num_concat (i32.load8_u offset=0 (local.get $offset.i16)))
        (call $num_concat (i32.load8_u offset=0 (local.get $offset.i8b)))
        (call $num_concat (i32.load8_u (local.get $index)))
    )

    (func $next_vector_index
        (result i32)
        (local $index i32)

        (if (i32.eq (global.get $MAX_COUNT) (local.tee $index (global.get $UUID_COUNT)))
            (then (console $error<ext> (text "Maximum UUID count exceed!")) (unreachable))
            (else (global.set $UUID_COUNT (local.get $index) (i32.add (i32.const 1))))
        )

        (if (i32.eqz (i32.and (global.get $UUID_COUNT) (i32.const 15)))
            (then (global.set $BLOCK_COUNT (i32.add (global.get $BLOCK_COUNT) (i32.const 1))))
        )
        
        (local.get $index)
    )

    (func $set_index_vector
        (param $index    i32)
        (param $vector  v128)
        (local $offsets v128)

        (v128.const i32x4 1 2 4 8)
        (i32x4.mul (i32x4.splat (local.get $index)))
        (i32x4.add (global.get $stride))
        (local.set $offsets)

        (i32.store8  (local.get $index)                          (i8x16.extract_lane_u 0 (local.get $vector))) 
        (i32.store8  (i32x4.extract_lane 0 (local.get $offsets)) (i8x16.extract_lane_u 1 (local.get $vector))) 
        (i32.store16 (i32x4.extract_lane 1 (local.get $offsets)) (i16x8.extract_lane_u 1 (local.get $vector))) 
        (i32.store   (i32x4.extract_lane 2 (local.get $offsets)) (i32x4.extract_lane   1 (local.get $vector))) 
        (i64.store   (i32x4.extract_lane 3 (local.get $offsets)) (i64x2.extract_lane   1 (local.get $vector))) 
    )


    (func $parse_uuid_vector
        (param $string externref)
        (result v128)
        (local $hexarr externref)
        (local $vector v128)

        (local.set $string (call $apply_replace_all (local.get $string) (global.get $ARGUMENTS_REGEXP_CLEAR_STR)))
        (local.set $hexarr (call $apply_match_regex (local.get $string) (global.get $ARGUMENTS_REGEXP_MATCH_HEX)))

        (v128.const i8x16 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)

        (i8x16.replace_lane  0 (call $parse_hex_at (local.get $hexarr) (i32.const 0)))
        (i8x16.replace_lane  1 (call $parse_hex_at (local.get $hexarr) (i32.const 1)))
        (i8x16.replace_lane  2 (call $parse_hex_at (local.get $hexarr) (i32.const 2)))
        (i8x16.replace_lane  3 (call $parse_hex_at (local.get $hexarr) (i32.const 3)))
        (i8x16.replace_lane  4 (call $parse_hex_at (local.get $hexarr) (i32.const 4)))
        (i8x16.replace_lane  5 (call $parse_hex_at (local.get $hexarr) (i32.const 5)))
        (i8x16.replace_lane  6 (call $parse_hex_at (local.get $hexarr) (i32.const 6)))
        (i8x16.replace_lane  7 (call $parse_hex_at (local.get $hexarr) (i32.const 7)))
        (i8x16.replace_lane  8 (call $parse_hex_at (local.get $hexarr) (i32.const 8)))
        (i8x16.replace_lane  9 (call $parse_hex_at (local.get $hexarr) (i32.const 9)))
        (i8x16.replace_lane 10 (call $parse_hex_at (local.get $hexarr) (i32.const 10)))
        (i8x16.replace_lane 11 (call $parse_hex_at (local.get $hexarr) (i32.const 11)))
        (i8x16.replace_lane 12 (call $parse_hex_at (local.get $hexarr) (i32.const 12)))
        (i8x16.replace_lane 13 (call $parse_hex_at (local.get $hexarr) (i32.const 13)))
        (i8x16.replace_lane 14 (call $parse_hex_at (local.get $hexarr) (i32.const 14)))
        (i8x16.replace_lane 15 (call $parse_hex_at (local.get $hexarr) (i32.const 15)))
    )


    (func $parse_hex_at
        (param $array <Array>)
        (param $index i32)
        (result i32)
        
        (call $self.parseInt<ext.i32>i32 
            (get.i32_extern (this) (local.get $index)) 
            (i32.const 16)
        )
    )

    (func $to_hexbyte_string
        (param $number i32)
        (result externref)

        (reflect $apply<ext.ext.ext>ext 
            (ref.extern $String:padStart) 
            (reflect $apply<ext.i32.ext>ext 
                (ref.extern $Number:toString) 
                (local.get $number) 
                (array $of<i32>ext (i32.const 16))
            ) 
            (array $of<i32.i32>ext (i32.const 2) (i32.const 0))
        )
    )

    (func $regexp_args_array
        (param $expression externref)
        (param $replaceWith externref)
        (result externref)

        (array $of<ext.ext>ext 
            (reflect $construct<ext.ext>ext 
                (ref.extern $RegExp) 
                (array $of<ext.ext>ext 
                    (local.get $expression) 
                    (text "gi")
                )
            )
            (local.get $replaceWith)
        )
    )

    (func $apply_replace_all
        (param $string externref)
        (param $expargs externref)
        (result externref)

        (reflect $apply<ext.ext.ext>ext 
            (ref.extern $String:replace) 
            (local.get $string) 
            (local.get $expargs)
        )
    )

    (func $apply_match_regex
        (param $string externref)
        (param $expargs externref)
        (result externref)

        (reflect $apply<ext.ext.ext>ext 
            (ref.extern $String:match) 
            (local.get $string) 
            (local.get $expargs)
        )
    )

    (func $str_concat
        (param $string externref)
        (param $prefix externref)
        (result externref)
        
        (reflect $apply<ext.ext.ext>ext
            (ref.extern $String:concat)
            (local.get $prefix)
            (array $of<ext>ext (local.get $string))
        )
    )

    (func $num_concat
        (param $string externref)
        (param $number i32)
        (result externref)
        
        (call $str_concat
            (local.get $string)
            (call $to_hexbyte_string (local.get $number))
        )
    )

    (func $calc_stride
        (param $size i32)
        (result v128)

        (v128.const i32x4 0 0 0 0)
        (i32x4.replace_lane 0 (i32.mul (i32.const 65536) (i32.div_u (local.get 0) (i32.const 16))))
        (i32x4.replace_lane 1 (i32.mul (i32.const 65536) (i32.div_u (local.get 0) (i32.const 8))))
        (i32x4.replace_lane 2 (i32.mul (i32.const 65536) (i32.div_u (local.get 0) (i32.const 4))))
        (i32x4.replace_lane 3 (i32.mul (i32.const 65536) (i32.div_u (local.get 0) (i32.const 2))))
    )

    (func $find
        (param $vector    v128)
        (result i32)

        (local $i8a_eq     v128)
        (local $i8b_eq     v128)
        (local $i8b_mask   v128)
        (local $i16_mask   v128)
        (local $i32_mask   v128)
        (local $i64_mask   v128)

        (local $i8a_splat  v128)
        (local $i8b_splat  v128)
        (local $i16_splat  v128)
        (local $i32_splat  v128)
        (local $i64_splat  v128)

        (local $i16_offset  i32)
        (local $i32_offset  i32)
        (local $i64_offset  i32)
        
        (local $offset i32)
        (local $length i32)

        (local.set $i8a_splat (i8x16.splat (i8x16.extract_lane_u 0 (local.get $vector))))
        (local.set $i8b_splat (i8x16.splat (i8x16.extract_lane_u 1 (local.get $vector))))
        (local.set $i16_splat (i16x8.splat (i16x8.extract_lane_u 1 (local.get $vector))))
        (local.set $i32_splat (i32x4.splat (i32x4.extract_lane   1 (local.get $vector))))
        (local.set $i64_splat (i64x2.splat (i64x2.extract_lane   1 (local.get $vector))))

        (local.set $offset (i32.sub (local.get $offset) (i32.const 16)))
        (local.set $length (i32.mul (global.get $BLOCK_COUNT) (i32.const 16)))

        (loop $blocks
            (if (i32.gt_u
                    (local.get $length)
                    (local.tee $offset (i32.add (local.get $offset) (i32.const 16)))
                )
                (then
                    (br_if $blocks (i32.eqz (v128.any_true 
                        (local.tee $i8a_eq (i8x16.eq (local.get $i8a_splat) (v128.load memory=i8x16a offset=0 (local.get $offset))))
                    )))

                    (br_if $blocks (i32.eqz (v128.any_true
                        (local.tee $i8b_eq (i8x16.eq (local.get $i8b_splat) (v128.load memory=i8x16b offset=0 (local.get $offset))))
                    )))

                    (br_if $blocks (i8x16.all_true (v128.not 
                        (local.tee $i8b_mask (v128.and (local.get $i8a_eq)(local.get $i8b_eq)))
                    )))

                    (local.set $i16_offset (i32.mul (i32.const 2) (local.get $offset)))
                    (local.set $i32_offset (i32.mul (i32.const 4) (local.get $offset)))
                    (local.set $i64_offset (i32.mul (i32.const 8) (local.get $offset)))

                    (local.set $i16_mask
                        (v128.and
                            (i16x8.extend_low_i8x16_s (local.get $i8b_mask))
                            (i16x8.eq (local.get $i16_splat) (v128.load memory=i16x8a offset=0 (local.get $i16_offset)))
                        )
                    )

                    (if (v128.any_true (local.get $i16_mask))
                        (then

                            (local.set $i32_mask
                                (v128.and
                                    (i32x4.extend_low_i16x8_s (local.get $i16_mask))
                                    (i32x4.eq (local.get $i32_splat) (v128.load memory=i32x4a offset=0 (local.get $i32_offset)))
                                )
                            )

                            (if (v128.any_true (local.get $i32_mask))
                                (then
                                    
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_low_i32x4_s (local.get $i32_mask)) ;; Maskeyi genişlet
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=0 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (local.get $i64_mask))
                                        (then
                                            ;; Lane 0 (Low) doluysa -> İndeks 0 bulundu
                                            (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 0)))
                                            ))
                                            ;; Lane 1 (High) doluysa -> İndeks 1 bulundu
                                            (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 1)))
                                            ))
                                        )
                                    )

                                    ;; --- Alt Grup: İndeks 2 ve 3 (i32 Maskesinin High tarafı) ---
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_high_i32x4_s (local.get $i32_mask)) ;; Maskeyi genişlet
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=16 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=16 (local.get $i64_offset))))
                                        (then
                                            ;; Lane 0 -> İndeks 2
                                            (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 2)))
                                            ))
                                            ;; Lane 1 -> İndeks 3
                                            (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 3)))
                                            ))
                                        )
                                    )
                                )
                            )

                            ;; -----------------------------------------------------------------
                            ;; GRUP 2: İndeks 4-7 (i16 Maskesinin ÜST yarısı)
                            ;; -----------------------------------------------------------------

                            ;; 2. C Bölgesini (i32x4a) offset=16'dan oku, karşılaştır ve maskele
                            (local.set $i32_mask
                                (v128.and
                                    (i32x4.extend_high_i16x8_s (local.get $i16_mask))
                                    (i32x4.eq (local.get $i32_splat) (v128.load memory=i32x4a offset=16 (local.get $i32_offset)))
                                )
                            )

                            (if (v128.any_true (local.get $i32_mask))
                                (then
                                    ;; --- Alt Grup: İndeks 4 ve 5 ---
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_low_i32x4_s (local.get $i32_mask))
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=32 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (local.get $i64_mask)) (then
                                        (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 4)))))
                                        (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 5)))))
                                    ))

                                    ;; --- Alt Grup: İndeks 6 ve 7 ---
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_high_i32x4_s (local.get $i32_mask))
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=48 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (local.get $i64_mask)) (then
                                        (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 6)))))
                                        (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 7)))))
                                    ))
                                )
                            )
                        )
                    )

                    (local.set $i16_mask
                        (v128.and
                            (i16x8.extend_high_i8x16_s (local.get $i8b_mask))
                            (i16x8.eq (local.get $i16_splat) (v128.load memory=i16x8a offset=16 (local.get $i16_offset)))
                        )
                    )

                    (if (v128.any_true (local.get $i16_mask))
                        (then

                            (local.set $i32_mask
                                (v128.and
                                    (i32x4.extend_low_i16x8_s (local.get $i16_mask))
                                    (i32x4.eq (local.get $i32_splat) (v128.load memory=i32x4a offset=32 (local.get $i32_offset)))
                                )
                            )

                            (if (v128.any_true (local.get $i32_mask))
                                (then
                                    
                                    ;; --- Alt Grup: İndeks 0 ve 1 (i32 Maskesinin Low tarafı) ---
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_low_i32x4_s (local.get $i32_mask)) ;; Maskeyi genişlet
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=64 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (local.get $i64_mask))
                                        (then
                                            ;; Lane 0 (Low) doluysa -> İndeks 0 bulundu
                                            (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 8)))
                                            ))
                                            ;; Lane 1 (High) doluysa -> İndeks 1 bulundu
                                            (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 9)))
                                            ))
                                        )
                                    )

                                    ;; --- Alt Grup: İndeks 2 ve 3 (i32 Maskesinin High tarafı) ---
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_high_i32x4_s (local.get $i32_mask)) ;; Maskeyi genişlet
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=80 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (local.get $i64_mask))
                                        (then
                                            ;; Lane 0 -> İndeks 2
                                            (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 10)))
                                            ))
                                            ;; Lane 1 -> İndeks 3
                                            (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 11)))
                                            ))
                                        )
                                    )
                                )
                            )

                            ;; -----------------------------------------------------------------
                            ;; GRUP 2: İndeks 4-7 (i16 Maskesinin ÜST yarısı)
                            ;; -----------------------------------------------------------------

                            ;; 2. C Bölgesini (i32x4a) offset=16'dan oku, karşılaştır ve maskele
                            (local.set $i32_mask
                                (v128.and
                                    (i32x4.extend_high_i16x8_s (local.get $i16_mask))
                                    (i32x4.eq (local.get $i32_splat) (v128.load memory=i32x4a offset=48 (local.get $i32_offset)))
                                )
                            )

                            (if (v128.any_true (local.get $i32_mask))
                                (then
                                    ;; --- Alt Grup: İndeks 4 ve 5 ---
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_low_i32x4_s (local.get $i32_mask))
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=96 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (local.get $i64_mask)) (then
                                        (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 12)))))
                                        (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 13)))))
                                    ))

                                    ;; --- Alt Grup: İndeks 6 ve 7 ---
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_high_i32x4_s (local.get $i32_mask))
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=112 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (local.get $i64_mask)) (then
                                        (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 14)))))
                                        (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 15)))))
                                    ))
                                )
                            )
                        )
                    )
                    
                    (br $blocks)
                )
            )
        )

        (i32.const -1)
    )
)(module 
    (include "shared/memory.wat")

    (main $core
        (console $log<ext.ext> (text "hello from worker module!") (self))

    )
)