
    (global $MUTEXT_TIMEOUT_SECS i64 (i64.secs 10))

    (global $WORKER_STATUS_CLOSED           i32 i32(0))
    (global $WORKER_STATUS_READY            i32 i32(1))
    (global $WORKER_STATUS_CLOSING          i32 i32(2))
    (global $WORKER_STATUS_TERMINATE_BEGIN  i32 i32(3))
    (global $WORKER_STATUS_TERMINATE_END    i32 i32(4))
    (global $WORKER_STATUS_CREATE_BEGIN     i32 i32(5))
    (global $WORKER_STATUS_CREATE_END       i32 i32(6))

    (func $set_process_extern_index (param i32) (i32.store offset=0 (global.get $MODULE_OFFSET) (this)))
    (func $get_process_extern_index (result i32) (i32.load offset=0 (global.get $MODULE_OFFSET)))

    (func $set_data_extern_index    (param i32) (i32.store offset=20 (global.get $MODULE_OFFSET) (this)))
    (func $get_data_extern_index    (result i32) (i32.load offset=20 (global.get $MODULE_OFFSET)))

    (func $set_new_worker_time      (param i32) (i32.store offset=4 (global.get $MODULE_OFFSET) (this)))
    (func $get_new_worker_time      (result i32) (i32.load offset=4 (global.get $MODULE_OFFSET)))

    (func $set_first_message_time   (param i32) (i32.store offset=8 (global.get $MODULE_OFFSET) (this)))
    (func $get_first_message_time   (result i32) (i32.load offset=8 (global.get $MODULE_OFFSET)))

    (func $set_current_status       (param i32) (i32.store offset=12 (global.get $MODULE_OFFSET) (this)))
    (func $get_current_status       (result i32) (i32.load offset=12 (global.get $MODULE_OFFSET)))
    (func $reset_status             (call $set_current_status (false)))

    (func $set_mutex_value          (param i32) (i32.store offset=16 (global.get $MODULE_OFFSET) (this)))
    (func $get_mutex_value          (result i32) (i32.load offset=16 (global.get $MODULE_OFFSET)))
    (func $has_notify               (result i32) (i32.eqz (call $get_mutex_value)))

    (func $unlock_mutex             (call $set_mutex_value (memory.atomic.notify offset=20 (global.get $MODULE_OFFSET) (true))))
    (func $reset_mutex              (call $set_mutex_value (false)))
    (func $lock_mutex               (call $set_mutex_value (memory.atomic.wait32 offset=20 (global.get $MODULE_OFFSET) (true) (global.get $MUTEXT_TIMEOUT_SECS))))

    (func $mark_sigint              (i32.atomic.store offset=24 (global.get $MODULE_OFFSET) (true)))
    (func $clear_sigint             (i32.atomic.store offset=24 (global.get $MODULE_OFFSET) (false)))
    (func $has_sigint               (result i32) (i32.atomic.load offset=24 (global.get $MODULE_OFFSET)))
