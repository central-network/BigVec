(module 
    (data $idb.wasm "file://../wasm/idb.wasm")
    (data $uuid.wasm "file://../wasm/uuid.wasm")
    (data $import.wasm "file://../wasm/import.wasm")
    (data $console.wasm "file://../wasm/console.wasm")

    (global $wasm new Object)

    (main $portal
        (set.extern (self) (text "wasm") (wasm))

        (async 
            (wasm.instantiate (data.view $import.wasm) (self))
            (then $oninstance
                (param $instance    <Object|Instance>)
                (result                     <Promise>)

                (object $assign<ext.ext> (wasm) (wasm.exports (this)))

                (wasm.instantiate (data.view $console.wasm) (self))
            )
            (then $onconsoleinstance
                (param $instance           <Instance>)
                (result                     <Promise>)

                (console $warn<ext.ext> (text "console started") (this))
                (wasm.instantiate (data.view $idb.wasm) (self))
            )
            (then $onidbinstance
                (param $instance           <Instance>)
                (result                     <Promise>)

                (console $warn<ext.ext> (text "idb started") (this))
                (wasm.instantiate (data.view $uuid.wasm) (self))
            )
            (then $onuuidinstance
                (param $instance           <Instance>)

                (console $warn<ext.ext> (text "uuid started") (this))
            )
        )
    )
)