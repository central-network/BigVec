(module
    (data $idb.wasm "file://../wasm/idb.wasm")
    (data $uuid.wasm "file://../wasm/uuid.wasm")

    (main $base
        (console $warn<ext.ext>
            (data.view $idb.wasm)
            (data.view $uuid.wasm)
        )
    )
)