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
)