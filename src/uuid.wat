(module
    (include "shared/imports.wat")
    (include "call_indirect/idb.wat")
    
    (memory $base {{PAGE_COUNT}})

    (global $MAX_COUNT   mut i32)
    (global $UUID_COUNT  mut i32)
    (global $BLOCK_COUNT mut i32)

    (global $ARGUMENTS_REGEXP_CLEAR_STR mut ext)
    (global $ARGUMENTS_REGEXP_MATCH_HEX mut ext)

    (global $stride (mut v128) (v128.const i32x4 0 0 0 0))

    (main $init
        (local $offset i32)

        (memory.size)
        (i32.mul (i32.const 65536))
        (i32.div_u (i32.const 16))
        (global.set $MAX_COUNT)
        (global.set $BLOCK_COUNT i32(1))

        (global.set $ARGUMENTS_REGEXP_CLEAR_STR (call $regexp_args_array (text "[^a-f0-9]") (string)))
        (global.set $ARGUMENTS_REGEXP_MATCH_HEX (call $regexp_args_array (text "(..)") (string)))

        (global.set $stride (call $calc_stride (memory.size)))

        (wasm.export (ref.module $uuid) (ref.func $indexOf))
        (wasm.export (ref.module $uuid) (ref.func $has))
        (wasm.export (ref.module $uuid) (ref.func $count))
        (wasm.export (ref.module $uuid) (ref.func $forEach))
        (wasm.export (ref.module $uuid) (ref.func $push))
        (wasm.export (ref.module $uuid) (ref.func $at))
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

    (func $count 
        (result i32) 
        (global.get $UUID_COUNT)
    )

    (func $has              
        (param $string  ext) 
        (result         i32) 
        
        (if (i32.ne 
                (i32.const -1) 
                (call $find (call $parse_uuid_vector (local.get $string)))
            )
            (then (return (i32.const 1)))
        )

        (i32.const 0)
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


    (func $parse_hex_at
        (param $array <Array>)
        (param $index i32)
        (result i32)
        
        (call $self.parseInt<ext.i32>i32 
            (get.i32_extern (this) (local.get $index)) 
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

    (func $find
        (param $vector    v128)
        (result i32)

        (local $i8a_eq     v128)
        (local $i8b_eq     v128)
        (local $i8b_mask   v128)
        (local $i16_mask   v128)
        (local $i32_mask   v128)
        (local $i64_mask   v128)

        (local $i8a_splat  v128)
        (local $i8b_splat  v128)
        (local $i16_splat  v128)
        (local $i32_splat  v128)
        (local $i64_splat  v128)

        (local $i16_offset  i32)
        (local $i32_offset  i32)
        (local $i64_offset  i32)
        
        (local $offset i32)
        (local $length i32)

        (local.set $i8a_splat (i8x16.splat (i8x16.extract_lane_u 0 (local.get $vector))))
        (local.set $i8b_splat (i8x16.splat (i8x16.extract_lane_u 1 (local.get $vector))))
        (local.set $i16_splat (i16x8.splat (i16x8.extract_lane_u 1 (local.get $vector))))
        (local.set $i32_splat (i32x4.splat (i32x4.extract_lane   1 (local.get $vector))))
        (local.set $i64_splat (i64x2.splat (i64x2.extract_lane   1 (local.get $vector))))

        (local.set $offset (i32.sub (local.get $offset) (i32.const 16)))
        (local.set $length (i32.mul (global.get $BLOCK_COUNT) (i32.const 16)))

        (loop $blocks
            (if (i32.gt_u
                    (local.get $length)
                    (local.tee $offset (i32.add (local.get $offset) (i32.const 16)))
                )
                (then
                    (br_if $blocks (i32.eqz (v128.any_true 
                        (local.tee $i8a_eq (i8x16.eq (local.get $i8a_splat) (v128.load memory=i8x16a offset=0 (local.get $offset))))
                    )))

                    (br_if $blocks (i32.eqz (v128.any_true
                        (local.tee $i8b_eq (i8x16.eq (local.get $i8b_splat) (v128.load memory=i8x16b offset=0 (local.get $offset))))
                    )))

                    (br_if $blocks (i8x16.all_true (v128.not 
                        (local.tee $i8b_mask (v128.and (local.get $i8a_eq)(local.get $i8b_eq)))
                    )))

                    (local.set $i16_offset (i32.mul (i32.const 2) (local.get $offset)))
                    (local.set $i32_offset (i32.mul (i32.const 4) (local.get $offset)))
                    (local.set $i64_offset (i32.mul (i32.const 8) (local.get $offset)))

                    (local.set $i16_mask
                        (v128.and
                            (i16x8.extend_low_i8x16_s (local.get $i8b_mask))
                            (i16x8.eq (local.get $i16_splat) (v128.load memory=i16x8a offset=0 (local.get $i16_offset)))
                        )
                    )

                    (if (v128.any_true (local.get $i16_mask))
                        (then

                            (local.set $i32_mask
                                (v128.and
                                    (i32x4.extend_low_i16x8_s (local.get $i16_mask))
                                    (i32x4.eq (local.get $i32_splat) (v128.load memory=i32x4a offset=0 (local.get $i32_offset)))
                                )
                            )

                            (if (v128.any_true (local.get $i32_mask))
                                (then
                                    
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_low_i32x4_s (local.get $i32_mask)) ;; Maskeyi genişlet
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=0 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (local.get $i64_mask))
                                        (then
                                            ;; Lane 0 (Low) doluysa -> İndeks 0 bulundu
                                            (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 0)))
                                            ))
                                            ;; Lane 1 (High) doluysa -> İndeks 1 bulundu
                                            (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 1)))
                                            ))
                                        )
                                    )

                                    ;; --- Alt Grup: İndeks 2 ve 3 (i32 Maskesinin High tarafı) ---
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_high_i32x4_s (local.get $i32_mask)) ;; Maskeyi genişlet
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=16 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=16 (local.get $i64_offset))))
                                        (then
                                            ;; Lane 0 -> İndeks 2
                                            (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 2)))
                                            ))
                                            ;; Lane 1 -> İndeks 3
                                            (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 3)))
                                            ))
                                        )
                                    )
                                )
                            )

                            ;; -----------------------------------------------------------------
                            ;; GRUP 2: İndeks 4-7 (i16 Maskesinin ÜST yarısı)
                            ;; -----------------------------------------------------------------

                            ;; 2. C Bölgesini (i32x4a) offset=16'dan oku, karşılaştır ve maskele
                            (local.set $i32_mask
                                (v128.and
                                    (i32x4.extend_high_i16x8_s (local.get $i16_mask))
                                    (i32x4.eq (local.get $i32_splat) (v128.load memory=i32x4a offset=16 (local.get $i32_offset)))
                                )
                            )

                            (if (v128.any_true (local.get $i32_mask))
                                (then
                                    ;; --- Alt Grup: İndeks 4 ve 5 ---
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_low_i32x4_s (local.get $i32_mask))
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=32 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (local.get $i64_mask)) (then
                                        (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 4)))))
                                        (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 5)))))
                                    ))

                                    ;; --- Alt Grup: İndeks 6 ve 7 ---
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_high_i32x4_s (local.get $i32_mask))
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=48 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (local.get $i64_mask)) (then
                                        (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 6)))))
                                        (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 7)))))
                                    ))
                                )
                            )
                        )
                    )

                    (local.set $i16_mask
                        (v128.and
                            (i16x8.extend_high_i8x16_s (local.get $i8b_mask))
                            (i16x8.eq (local.get $i16_splat) (v128.load memory=i16x8a offset=16 (local.get $i16_offset)))
                        )
                    )

                    (if (v128.any_true (local.get $i16_mask))
                        (then

                            (local.set $i32_mask
                                (v128.and
                                    (i32x4.extend_low_i16x8_s (local.get $i16_mask))
                                    (i32x4.eq (local.get $i32_splat) (v128.load memory=i32x4a offset=32 (local.get $i32_offset)))
                                )
                            )

                            (if (v128.any_true (local.get $i32_mask))
                                (then
                                    
                                    ;; --- Alt Grup: İndeks 0 ve 1 (i32 Maskesinin Low tarafı) ---
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_low_i32x4_s (local.get $i32_mask)) ;; Maskeyi genişlet
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=64 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (local.get $i64_mask))
                                        (then
                                            ;; Lane 0 (Low) doluysa -> İndeks 0 bulundu
                                            (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 8)))
                                            ))
                                            ;; Lane 1 (High) doluysa -> İndeks 1 bulundu
                                            (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 9)))
                                            ))
                                        )
                                    )

                                    ;; --- Alt Grup: İndeks 2 ve 3 (i32 Maskesinin High tarafı) ---
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_high_i32x4_s (local.get $i32_mask)) ;; Maskeyi genişlet
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=80 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (local.get $i64_mask))
                                        (then
                                            ;; Lane 0 -> İndeks 2
                                            (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 10)))
                                            ))
                                            ;; Lane 1 -> İndeks 3
                                            (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                                (return (i32.add (local.get $offset) (i32.const 11)))
                                            ))
                                        )
                                    )
                                )
                            )

                            ;; -----------------------------------------------------------------
                            ;; GRUP 2: İndeks 4-7 (i16 Maskesinin ÜST yarısı)
                            ;; -----------------------------------------------------------------

                            ;; 2. C Bölgesini (i32x4a) offset=16'dan oku, karşılaştır ve maskele
                            (local.set $i32_mask
                                (v128.and
                                    (i32x4.extend_high_i16x8_s (local.get $i16_mask))
                                    (i32x4.eq (local.get $i32_splat) (v128.load memory=i32x4a offset=48 (local.get $i32_offset)))
                                )
                            )

                            (if (v128.any_true (local.get $i32_mask))
                                (then
                                    ;; --- Alt Grup: İndeks 4 ve 5 ---
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_low_i32x4_s (local.get $i32_mask))
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=96 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (local.get $i64_mask)) (then
                                        (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 12)))))
                                        (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 13)))))
                                    ))

                                    ;; --- Alt Grup: İndeks 6 ve 7 ---
                                    (local.set $i64_mask 
                                        (v128.and
                                            (i64x2.extend_high_i32x4_s (local.get $i32_mask))
                                            (i64x2.eq (local.get $i64_splat) (v128.load memory=i64x2a offset=112 (local.get $i64_offset)))
                                        )
                                    )

                                    (if (v128.any_true (local.get $i64_mask)) (then
                                        (if (i32.wrap_i64 (i64x2.extract_lane 0 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 14)))))
                                        (if (i32.wrap_i64 (i64x2.extract_lane 1 (local.get $i64_mask))) (then
                                            (return (i32.add (local.get $offset) (i32.const 15)))))
                                    ))
                                )
                            )
                        )
                    )
                    
                    (br $blocks)
                )
            )
        )

        (i32.const -1)
    )
)