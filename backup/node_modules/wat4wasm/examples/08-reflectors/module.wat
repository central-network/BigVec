(module 
    (func $01-console.*

        (text "hello world")
        (console $log<ext>)

        (text "bye bye world") (i32.const -1)
        (console $log<ext.i32>)

        (NaN)
        (console $warn<ext>)
    )

    (func $02-array.*

        (array $of<ext>ext (string "🦋"))
        (drop)

        (array $isArray<ext>i32 (array))
        (drop)

        (array $fromAsync<ext>ext (array))
        (drop)
    )

    (func $03-object.*

        (object $is<ext.ext>i32 (null) (undefined))
        (drop)

        (object $is<ext.f32>i32 (NaN) (f32.const nan))
        (drop)

        (object $fromEntries<ext>ext (array))
        (drop)
    )

    (func $04-reflect.*

        (reflect $set<ext.ext.ext>i32 
            (global.get $self) (text "name") (text "test")
        )
        (drop)

        (reflect $get<ext.ext>ext 
            (self) (text "name")
        )
        (drop)

        (reflect $apply<ext.ext.ext>ext 
            (ref.extern $Math.floor<ext>) (null) (array $of<f32>ext (f32.const 2.1))
        )
        (drop)

        (reflect $construct<ext.ext>ext 
            (ref.extern $Object<ext>) (array)
        )
        (drop)

        (reflect $ownKeys<ext>ext 
            (ref.extern $ArrayBuffer<ext>) 
        )
        (drop)

        (reflect $getPrototypeOf<ext>ext 
            (self) 
        )
        (drop)

        (reflect $getOwnPropertyDescriptor<ext.ext>ext 
            (self) (text "name")
        )
        (drop)
    )

    (func $05-string.*

        (string $fromCharCode<i32.i32>ext (i32.const 46) (i32.const 47))
        (drop) 
    )
    
    (func $06-number.*

        (number $isSafeInteger<i32>i32 (i32.const 47))
        (drop)

        (number $isNaN<ext>i32 (self))
        (drop)
    )

    (func $07-math.*

        (math $max<f32.f32>f32 (f32.const 47.2) (f32.const 42.7))
        (drop)
 
        (math $random<>f32)
        (drop)
    )

    (func $08-url.*

        (url $createObjectURL<ext>ext (new $MediaSource))
        (drop)

        (url $revokeObjectURL<ext> (null))
        (nop)
    )
)