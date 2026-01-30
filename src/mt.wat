(module
    (include "shared/memory.wat")
    (include "shared/imports.wat")

    (data $worker.js "file://worker.js")

    (global $MODULE_OFFSET mut i32)
    (global $WORKER_OFFSET mut i32)
    (global $MODULE_LENGTH i32 i32(256))

    (global $MODULE_HEADER_LENGTH i32 i32(48))
    (global $WORKER_HEADER_LENGTH i32 i32(16))

    (func $set_hardware_concurrency (param i32) (i32.atomic.store8                      offset=4 (global.get $MODULE_OFFSET) (local.get 0)))
    (func $get_hardware_concurrency (result i32) (i32.atomic.load8_u                    offset=4 (global.get $MODULE_OFFSET)))

    (func $set_maximum_thread_count (param i32) (i32.atomic.store8                      offset=5 (global.get $MODULE_OFFSET) (local.get 0)))
    (func $get_maximum_thread_count (result i32) (i32.atomic.load8_u                    offset=5 (global.get $MODULE_OFFSET)))

    (func $set_malloc_worker_offset (param i32) (i32.atomic.store8                      offset=6 (global.get $MODULE_OFFSET) (local.get 0)))
    (func $get_malloc_worker_offset (result i32) (i32.atomic.load8_u                    offset=6 (global.get $MODULE_OFFSET)))
    (func $add_malloc_worker_offset (result i32) (i32.atomic.rmw8.add_u                 offset=6 (global.get $MODULE_OFFSET) (global.get $WORKER_HEADER_LENGTH)))
    (func $sub_malloc_worker_offset (result i32) (i32.atomic.rmw8.sub_u                 offset=6 (global.get $MODULE_OFFSET) (global.get $WORKER_HEADER_LENGTH)))

    (func $set_opening_worker_count (param i32) (i32.atomic.store8                      offset=8 (global.get $MODULE_OFFSET) (local.get 0)))
    (func $get_opening_worker_count (result i32) (i32.atomic.load8_u                    offset=8 (global.get $MODULE_OFFSET)))
    (func $add_opening_worker_count (result i32) (i32.atomic.rmw8.add_u                 offset=8 (global.get $MODULE_OFFSET) (i32.const 1)))
    (func $sub_opening_worker_count (result i32) (i32.atomic.rmw8.add_u                 offset=8 (global.get $MODULE_OFFSET) (i32.const -1)))

    (func $set_working_worker_count (param i32) (i32.atomic.store8                      offset=9 (global.get $MODULE_OFFSET) (local.get 0)))
    (func $get_working_worker_count (result i32) (i32.atomic.load8_u                    offset=9 (global.get $MODULE_OFFSET)))
    (func $add_working_worker_count (result i32) (i32.atomic.rmw8.add_u                 offset=9 (global.get $MODULE_OFFSET) (i32.const 1)))
    (func $sub_working_worker_count (result i32) (i32.atomic.rmw8.add_u                 offset=9 (global.get $MODULE_OFFSET) (i32.const -1)))

    (func $set_closing_worker_count (param i32) (i32.atomic.store8                      offset=10 (global.get $MODULE_OFFSET) (local.get 0)))
    (func $get_closing_worker_count (result i32) (i32.atomic.load8_u                    offset=10 (global.get $MODULE_OFFSET)))
    (func $add_closing_worker_count (result i32) (i32.atomic.rmw8.add_u                 offset=10 (global.get $MODULE_OFFSET) (i32.const 1)))
    (func $sub_closing_worker_count (result i32) (i32.atomic.rmw8.add_u                 offset=10 (global.get $MODULE_OFFSET) (i32.const -1)))

    (func $set_waiting_worker_count (param i32) (i32.atomic.store8                      offset=11 (global.get $MODULE_OFFSET) (local.get 0)))
    (func $get_waiting_worker_count (result i32) (i32.atomic.load8_u                    offset=11 (global.get $MODULE_OFFSET)))
    (func $add_waiting_worker_count (result i32) (i32.atomic.rmw8.add_u                 offset=11 (global.get $MODULE_OFFSET) (i32.const 1)))
    (func $sub_waiting_worker_count (result i32) (i32.atomic.rmw8.add_u                 offset=11 (global.get $MODULE_OFFSET) (i32.const -1)))

    (func $set_worker_opening_index (param i32 i32) (i32.atomic.store8                  offset=0 (this) (local.get 1)))
    (func $get_worker_opening_index (param i32) (result i32) (i32.atomic.load8_u        offset=0 (this)))

    (func $set_worker_working_index (param i32 i32) (i32.atomic.store8                  offset=1 (this) (local.get 1)))
    (func $get_worker_working_index (param i32) (result i32) (i32.atomic.load8_u        offset=1 (this)))

    (func $set_worker_closing_index (param i32 i32) (i32.atomic.store8                  offset=2 (this) (local.get 1)))
    (func $get_worker_closing_index (param i32) (result i32) (i32.atomic.load8_u        offset=2 (this)))

    (func $set_worker_waiting_index (param i32 i32) (i32.atomic.store8                  offset=3 (this) (local.get 1)))
    (func $get_worker_waiting_index (param i32) (result i32) (i32.atomic.load8_u        offset=3 (this)))

    (func $set_worker_extern_index (param i32 i32) (i32.store                           offset=4 (this) (local.get 1)))
    (func $get_worker_extern_index (param i32) (result i32) (i32.load                   offset=4 (this)))

    (func $set_worker_opening_time (param i32 i32) (i32.store                           offset=8 (this) (local.get 1)))
    (func $get_worker_opening_time (param i32) (result i32) (i32.load                   offset=8 (this)))

    (func $set_worker_waiting_time (param i32 i32) (i32.store                           offset=12 (this) (local.get 1)))
    (func $get_worker_waiting_time (param i32) (result i32) (i32.load                   offset=12 (this)))

    (global $ARGUMENTS_ONMESSAGE_ONCE new Array)

    (main $mt
        (debug "hello from mt")

        (global.set $MODULE_OFFSET  
            (malloc (global.get $MODULE_LENGTH))
        )

        (global.set $WORKER_OFFSET  
            (i32.add 
                (global.get $MODULE_OFFSET)
                (global.get $MODULE_HEADER_LENGTH)
            )
        )

        (set.i32_extern (global.get $ARGUMENTS_ONMESSAGE_ONCE) i32(0) (text "message"))
        (set.i32_extern (global.get $ARGUMENTS_ONMESSAGE_ONCE) i32(2) (object))
        (set.extern_i32 (get.i32_extern (global.get $ARGUMENTS_ONMESSAGE_ONCE) i32(2)) (text "once") (true))
        
        (call $set_malloc_worker_offset (global.get $WORKER_OFFSET))
        (call $create_worker)

        (call $self.setTimeout<ext.i32>
            (reflect $apply<ext.fun.ext>ext
                (ref.extern $Function:bind)
                (ref.func $terminate_worker)
                (array $of<ext.i32>ext (null) (i32.const 64))
            )
            i32(1000)
        )
    )

    (func $reference_extern
        (param $any     externref)
        (result                 i32)
        (table.grow $externref (this) (true))
    )

    (func $new_worker
        (result <Worker>)
        (reflect $construct<ext.ext>ext (ref.extern $Worker) (array $of<ext>ext (data.url $worker.js)))
    )

    (func $performance_now
        (result i32)
        (reflect $apply<ext.ext.ext>i32 (ref.extern $Performance:now) (ref.extern $performance) (array))
    )

    (func $listen_worker_once
        (param $memory_offset        i32)
        (param $listener         funcref)

        (reflect $set<ext.i32.ext>
            (global.get $ARGUMENTS_ONMESSAGE_ONCE) 
            (i32.const 1) 
            (reflect $apply<ext.fun.ext>ext
                (ref.extern $Function:bind)
                (local.get $listener)
                (array $of<ext.i32>ext (null) (this))
            )
        )
        
        (reflect $apply<ext.ext.ext> 
            (ref.extern $EventTarget:addEventListener) 
            (table.get $externref (call $get_worker_extern_index (this))) 
            (global.get $ARGUMENTS_ONMESSAGE_ONCE)
        )
    )

    (func $dereference_worker
        (param $memory_offset i32)
        (result          <Worker>)
        (table.get $externref (call $get_worker_extern_index (this)))
    )

    (func $onworkermessage/init
        (param $worker_offset i32)

        (call $set_worker_opening_index (this) (call $sub_opening_worker_count))
        (call $set_worker_waiting_index (this) (call $add_waiting_worker_count))
        (call $set_worker_waiting_time  (this) (call $performance_now))
    )

    (func $create_worker
        (local $memory_offset        i32)
        (local $worker_thread   <Worker>)
        (local $worker_index         i32)
        (local $extern_index         i32)

        (local.set $memory_offset (call $add_malloc_worker_offset))
        (local.set $worker_index  (call $add_opening_worker_count))
        (local.set $worker_thread (call $new_worker))
        (local.set $extern_index  (call $reference_extern (local.get $worker_thread)))

        (call $set_worker_opening_index (this) (local.get $worker_index))
        (call $set_worker_extern_index  (this) (local.get $extern_index))
        (call $listen_worker_once       (this) (ref.func $onworkermessage/init))
        (call $set_worker_opening_time  (this) (call $performance_now))
    )

    (func $terminate_worker
        (param $memory_offset        i32)
        (local $closing_index        i32)
        (local $worker_thread        <Worker>)

        (local.set $closing_index  (call $add_closing_worker_count))
        (local.set $worker_thread  (call $dereference_worker (this)))

        (reflect $apply<ext.ext.ext> 
            (ref.extern $Worker:terminate) 
            (local.get $worker_thread) 
            (array)
        )

        (table.set $externref (call $get_worker_extern_index (this)) (null))

        (call $set_worker_opening_index (this) (false))
        (call $set_worker_working_index (this) (false))
        (call $set_worker_closing_index (this) (false))
        (call $set_worker_waiting_index (this) (false))
    )

    (func $close_worker
        (; do this atomic over memory then wait for terminate ;)
    )

    (func $set_worker_status_opening
        (param $offset i32)

        (call $set_worker_opening_index (this) (call $add_opening_worker_count))
        (call $set_worker_working_index (this) (call $add_working_worker_count))
        (call $set_worker_closing_index (this) (call $add_closing_worker_count))
        (call $set_worker_waiting_index (this) (call $add_waiting_worker_count))
    )
)