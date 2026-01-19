
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

                            (local.set $i32_mask (i32x4.extend_low_i16x8_s (local.get $i16_mask)))
                            (local.set $i32_mask
                                (v128.and
                                    (local.get $i32_mask) ;; Üstten gelen vize
                                    (i32x4.eq (local.get $i32_splat) (v128.load memory=i32x4a offset=0 (local.get $i32_offset)))
                                )
                            )

                            (if (v128.any_true (local.get $i32_mask))
                                (then
                                    
                                    ;; --- Alt Grup: İndeks 0 ve 1 (i32 Maskesinin Low tarafı) ---
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

                            ;; 1. i16 maskesinin son yarısını i32 formatına genişlet
                            (local.set $i32_mask (i32x4.extend_high_i16x8_s (local.get $i16_mask)))
                            
                            ;; 2. C Bölgesini (i32x4a) offset=16'dan oku, karşılaştır ve maskele
                            (local.set $i32_mask
                                (v128.and
                                    (local.get $i32_mask)
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

                            (local.set $i32_mask (i32x4.extend_low_i16x8_s (local.get $i16_mask)))
                            (local.set $i32_mask
                                (v128.and
                                    (local.get $i32_mask) ;; Üstten gelen vize
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

                            ;; 1. i16 maskesinin son yarısını i32 formatına genişlet
                            (local.set $i32_mask (i32x4.extend_high_i16x8_s (local.get $i16_mask)))
                            
                            ;; 2. C Bölgesini (i32x4a) offset=16'dan oku, karşılaştır ve maskele
                            (local.set $i32_mask
                                (v128.and
                                    (local.get $i32_mask)
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