(module
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
)