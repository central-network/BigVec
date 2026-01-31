(module
    (include "shared/memory.wat")
    (include "shared/worker.wat")

    (import "wasm" "offset" (global $MODULE_OFFSET i32))
    (import "wasm" "length" (global $MODULE_LENGTH i32))

    (main $worker_thread
        (console $warn<ext.i32.i32.ext>
            (text "worker thread started")
            (global.get $MODULE_OFFSET)
            (global.get $MODULE_LENGTH)
            (self)
        )

        (warn (self))

        (set.extern (self) (text "onerror") (ref.extern $close))
        (set.extern (self) (text "onunhandledrejection") (ref.extern $close))

        (call $mutex_loop)
        (unreachable)
    )

    (func $mutex_loop
        (block $close
            (loop $while
                (call $set_current_status (global.get $WORKER_STATUS_READY))
                (call $lock_mutex) 
                (debug "mutex unlocked")

                (console $error<i32> (call $get_mutex_value))

                (br_if $close (call $has_sigint))
                (br_if $while (call $has_notify))
            )

            (call $set_current_status (global.get $WORKER_STATUS_CLOSED))
            (call $self.close<>)
        )
    )
)