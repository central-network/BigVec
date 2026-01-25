(module 
    (func $main
        (async
            (call $new_Promise)
            (then ref.func $then_binding)
            (catch ref.func $catch_binding)
            (finally ref.func $finally_binding)
        )
    )

    (func $new_Promise (result externref) (null))
    (func $then_binding (param $any externref))
    (func $catch_binding (param $any externref))
    (func $finally_binding (param $any externref))
)