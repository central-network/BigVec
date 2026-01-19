

    (func $stats
        (console $table<ext>
            (object $fromEntries<ext>ext
                (array $of<ext.ext>ext
                    (array $of<ext.i32>ext (text "TOTAL_UUID_COUNT") (global.get $UUID_COUNT))
                    (array $of<ext.i32>ext (text "TOTAL_BLOCK_COUNT") (global.get $BLOCK_COUNT))
                )
            )
        )
    )

    (func $forEach
        (param $callback externref)
        (param $thisArg  externref)
        (local $iterator      v128)
        (local $iterated      v128)

        (local.set $iterator (v128.const i32x4 -1 4 1 0))
        (local.set $iterated (i32x4.replace_lane 0 (local.get $iterated) (global.get $UUID_COUNT)))

        (loop $iteration
            (if (i32x4.extract_lane 0 (local.get $iterated))
                (then
                    (reflect $apply<ext.ext.ext>
                        (local.get $callback)
                        (local.get $thisArg)
                        (array $of<ext.i32>ext
                            (call $at (i32x4.extract_lane 2 (local.get $iterated)))
                            (i32x4.extract_lane 2 (local.get $iterated))
                        )
                    )

                    (local.set $iterated
                        (i32x4.add (local.get $iterated) (local.get $iterator))
                    )
                    
                    (br $iteration)
                )
            )
        )
    )

    (func $count (result i32) (global.get $UUID_COUNT))

    (func $contains              
        (param $string  ext) 
        (result         ext) 
        
        (if (i32.ne 
                (i32.const -1) 
                (call $find (call $parse_uuid_vector (local.get $string)))
            )
            (then (return (global.get $true)))
        )

        (global.get $false)
    )

    (func $indexOf
        (param $string externref)
        (result i32)
        (call $find (call $parse_uuid_vector (local.get $string)))
    )

    (func $push
        (param $string externref)
        (result i32)
        (local $index i32)

        (call $set_index_vector
            (local.tee $index (call $next_vector_index))
            (call $parse_uuid_vector (local.get $string))
        )        

        (local.get $index)
    )
    
    (func $at
        (param $index i32)
        (result externref)

        (local $offset v128)
        (local $offset.i8b i32)
        (local $offset.i16 i32)
        (local $offset.i32 i32)
        (local $offset.i64 i32)

        (if (i32.lt_s (local.get $index) (i32.const 0))
            (then (local.set $index (i32.add (global.get $UUID_COUNT) (local.get $index))))
        )

        (v128.const i32x4 1 2 4 8) 
        (i32x4.mul (i32x4.splat (local.get $index)))
        (i32x4.add (global.get $stride))
        (local.set $offset)

        (local.set $offset.i8b (i32x4.extract_lane 0 (local.get $offset)))
        (local.set $offset.i16 (i32x4.extract_lane 1 (local.get $offset)))
        (local.set $offset.i32 (i32x4.extract_lane 2 (local.get $offset)))
        (local.set $offset.i64 (i32x4.extract_lane 3 (local.get $offset)))        

        (string)
        (call $num_concat (i32.load8_u offset=7 (local.get $offset.i64)))
        (call $num_concat (i32.load8_u offset=6 (local.get $offset.i64)))
        (call $num_concat (i32.load8_u offset=5 (local.get $offset.i64)))
        (call $num_concat (i32.load8_u offset=4 (local.get $offset.i64)))
        (call $num_concat (i32.load8_u offset=3 (local.get $offset.i64)))
        (call $num_concat (i32.load8_u offset=2 (local.get $offset.i64)))
        (call $str_concat (text "-"))
        (call $num_concat (i32.load8_u offset=1 (local.get $offset.i64)))
        (call $num_concat (i32.load8_u offset=0 (local.get $offset.i64)))
        (call $str_concat (text "-"))
        (call $num_concat (i32.load8_u offset=3 (local.get $offset.i32)))
        (call $num_concat (i32.load8_u offset=2 (local.get $offset.i32)))
        (call $str_concat (text "-"))
        (call $num_concat (i32.load8_u offset=1 (local.get $offset.i32)))
        (call $num_concat (i32.load8_u offset=0 (local.get $offset.i32)))
        (call $str_concat (text "-"))
        (call $num_concat (i32.load8_u offset=1 (local.get $offset.i16)))
        (call $num_concat (i32.load8_u offset=0 (local.get $offset.i16)))
        (call $num_concat (i32.load8_u offset=0 (local.get $offset.i8b)))
        (call $num_concat (i32.load8_u (local.get $index)))
    )

    (func $set_index_vector
        (param $index    i32)
        (param $vector  v128)
        (local $offsets v128)

        (v128.const i32x4 1 2 4 8)
        (i32x4.mul (i32x4.splat (local.get $index)))
        (i32x4.add (global.get $stride))
        (local.set $offsets)

        (i32.store8  (local.get $index)                          (i8x16.extract_lane_u 0 (local.get $vector))) 
        (i32.store8  (i32x4.extract_lane 0 (local.get $offsets)) (i8x16.extract_lane_u 1 (local.get $vector))) 
        (i32.store16 (i32x4.extract_lane 1 (local.get $offsets)) (i16x8.extract_lane_u 1 (local.get $vector))) 
        (i32.store   (i32x4.extract_lane 2 (local.get $offsets)) (i32x4.extract_lane   1 (local.get $vector))) 
        (i64.store   (i32x4.extract_lane 3 (local.get $offsets)) (i64x2.extract_lane   1 (local.get $vector))) 
    )

    (func $next_vector_index
        (result i32)
        (local $index i32)

        (if (i32.eq (global.get $MAX_COUNT) (local.tee $index (global.get $UUID_COUNT)))
            (then (console $error<ext> (text "Maximum UUID count exceed!")) (unreachable))
            (else (global.set $UUID_COUNT (local.get $index) (i32.add (i32.const 1))))
        )

        (if (i32.eqz (i32.and (global.get $UUID_COUNT) (i32.const 15)))
            (then (global.set $BLOCK_COUNT (i32.add (global.get $BLOCK_COUNT) (i32.const 1))))
        )

        (local.get $index)
    )

    (func $parse_uuid_vector
        (param $string externref)
        (result v128)
        (local $hexarr externref)
        (local $vector v128)

        (local.set $string (call $apply_replace_all (local.get $string) (global.get $ARGUMENTS_REGEXP_CLEAR_STR)))
        (local.set $hexarr (call $apply_match_regex (local.get $string) (global.get $ARGUMENTS_REGEXP_MATCH_HEX)))

        (v128.const i8x16 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)

        (i8x16.replace_lane  0 (call $parse_hex_at (local.get $hexarr) (i32.const 0)))
        (i8x16.replace_lane  1 (call $parse_hex_at (local.get $hexarr) (i32.const 1)))
        (i8x16.replace_lane  2 (call $parse_hex_at (local.get $hexarr) (i32.const 2)))
        (i8x16.replace_lane  3 (call $parse_hex_at (local.get $hexarr) (i32.const 3)))
        (i8x16.replace_lane  4 (call $parse_hex_at (local.get $hexarr) (i32.const 4)))
        (i8x16.replace_lane  5 (call $parse_hex_at (local.get $hexarr) (i32.const 5)))
        (i8x16.replace_lane  6 (call $parse_hex_at (local.get $hexarr) (i32.const 6)))
        (i8x16.replace_lane  7 (call $parse_hex_at (local.get $hexarr) (i32.const 7)))
        (i8x16.replace_lane  8 (call $parse_hex_at (local.get $hexarr) (i32.const 8)))
        (i8x16.replace_lane  9 (call $parse_hex_at (local.get $hexarr) (i32.const 9)))
        (i8x16.replace_lane 10 (call $parse_hex_at (local.get $hexarr) (i32.const 10)))
        (i8x16.replace_lane 11 (call $parse_hex_at (local.get $hexarr) (i32.const 11)))
        (i8x16.replace_lane 12 (call $parse_hex_at (local.get $hexarr) (i32.const 12)))
        (i8x16.replace_lane 13 (call $parse_hex_at (local.get $hexarr) (i32.const 13)))
        (i8x16.replace_lane 14 (call $parse_hex_at (local.get $hexarr) (i32.const 14)))
        (i8x16.replace_lane 15 (call $parse_hex_at (local.get $hexarr) (i32.const 15)))
    )
