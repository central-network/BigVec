
    (func $parse_hex_at
        (param $array <Array>)
        (param $index i32)
        (result i32)
        
        (call $self.parseInt<ext.i32>i32 
            (reflect $get<ext.i32>ext (local.get $array) (local.get $index)) 
            (i32.const 16)
        )
    )

    (func $to_hexbyte_string
        (param $number i32)
        (result externref)

        (reflect $apply<ext.ext.ext>ext 
            (ref.extern $String:padStart) 
            (reflect $apply<ext.i32.ext>ext 
                (ref.extern $Number:toString) 
                (local.get $number) 
                (array $of<i32>ext (i32.const 16))
            ) 
            (array $of<i32.i32>ext (i32.const 2) (i32.const 0))
        )
    )

    (func $regexp_args_array
        (param $expression externref)
        (param $replaceWith externref)
        (result externref)

        (array $of<ext.ext>ext 
            (reflect $construct<ext.ext>ext 
                (ref.extern $RegExp) 
                (array $of<ext.ext>ext 
                    (local.get $expression) 
                    (text "gi")
                )
            )
            (local.get $replaceWith)
        )
    )

    (func $apply_replace_all
        (param $string externref)
        (param $expargs externref)
        (result externref)

        (reflect $apply<ext.ext.ext>ext 
            (ref.extern $String:replace) 
            (local.get $string) 
            (local.get $expargs)
        )
    )

    (func $apply_match_regex
        (param $string externref)
        (param $expargs externref)
        (result externref)

        (reflect $apply<ext.ext.ext>ext 
            (ref.extern $String:match) 
            (local.get $string) 
            (local.get $expargs)
        )
    )

    (func $str_concat
        (param $string externref)
        (param $prefix externref)
        (result externref)
        
        (reflect $apply<ext.ext.ext>ext
            (ref.extern $String:concat)
            (local.get $prefix)
            (array $of<ext>ext (local.get $string))
        )
    )

    (func $num_concat
        (param $string externref)
        (param $number i32)
        (result externref)
        
        (call $str_concat
            (local.get $string)
            (call $to_hexbyte_string (local.get $number))
        )
    )

    (func $calc_stride
        (param $size i32)
        (result v128)

        (v128.const i32x4 0 0 0 0)
        (i32x4.replace_lane 0 (i32.mul (i32.const 65536) (i32.div_u (local.get 0) (i32.const 16))))
        (i32x4.replace_lane 1 (i32.mul (i32.const 65536) (i32.div_u (local.get 0) (i32.const 8))))
        (i32x4.replace_lane 2 (i32.mul (i32.const 65536) (i32.div_u (local.get 0) (i32.const 4))))
        (i32x4.replace_lane 3 (i32.mul (i32.const 65536) (i32.div_u (local.get 0) (i32.const 2))))
    )
