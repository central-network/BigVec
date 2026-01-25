(module 
    (data (i32.const 4) "file://used-folder/clear-text.txt")

    (func $01-basic
        (i32.load (i32.const 4))
        (drop)
    )


    (data $passive "file://used-folder/clear-text.txt")

    (func $02-size
        (data.size $passive)
        (drop)
    )

    (func $03-view
        (data.view $passive)
        (drop)
    )


    (data $wat->wasm "wasm://used-folder/compile-this.wat")

    (func $04-module
        (data.view $wat->wasm)
        (drop)
    )
)