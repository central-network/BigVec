(module 
    (data $worker.wasm "wasm://sub/worker.wat")

    (main $init
        (data.view $worker.wasm)
        (drop)
    )
)