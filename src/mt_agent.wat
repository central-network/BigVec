(module
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
)