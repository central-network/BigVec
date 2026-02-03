(module
    (global $wasm new Object)

    (data $ins "wasm://n.wat")
    (data $sec "file://../wasm/s.wasm")

    (main $test
        (local $any externref)
        (debug "hello babee")

        (local.set $any 
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $Function:bind)
                (ref.extern $Function:call)
                (array $of<ext>ext (ref.extern $MessageEvent:data[get]))
            )
        )

        (set.extern (self) (text "getter") (this))

        (local.set $any 
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $Function:bind)
                (ref.extern $Function:call)
                (array $of<ext>ext (ref.extern $EventTarget:addEventListener))
            )
        )

        (set.extern (self) (text "listen") (this))


        (set.extern (self) (text "log") (ref.extern $console.log))

        (async
            (wasm.instantiate (data.view $ins))
            (then $oninst
                (param $anty externref)
                (result <Promise>)

                (object $assign<ext.ext> (self) (wasm.exports (this)))
                (wasm.instantiate (data.view $sec))
            )
            (then $onsec
                (param $anty externref)
                (warn (this))
            )
        )
        
    )
)