(module
        (import "wasm" "funcref" (table $funcref 5 65536 funcref))
        (import "wasm" "externref" (table $externref 5 65536 externref))
        (import "wasm" "textref" (table $textref 35 65536 externref))
    

    (; 985cf59650640d4795387c047a446cd9 ;)

    (func $strf

    )

    (func $init
        (local $count i32)
        (local $cursor i32)
        (local $readed_value i32)
        (local $stepKeyCursor i32)
        (local $finalizeFlag i32)
        (local $current_hash i32)
        (local $charCodeArray externref)
        (local $parent externref)
        (local $name externref)
        (local $fullpath externref)
        (local $pathcursor externref)

        (local.set $parent (global.get $self))

        (block $done 
            (local.set $count (i32.const 4))

            (loop $next_item_fetch_loop
                (i32.sub (local.get $count) (i32.const 1))
                (br_if $done (i32.eqz (local.tee $count)))

                (local.set $fullpath        (call $array))
                (local.set $steppath        (call $array))
                (local.set $finalizeFlag    (i32.const 0))
                (local.set $current_hash    (i32.const 0))

                (loop $read_charcodes_continously
                    (local.tee $readed_value (i32.load (local.get $cursor)))
                    (br_if $done (i32.eqz))
                                   
                    (local.set $cursor      (i32.add (local.get $cursor) (i32.const 1)))
                    (local.set $keycursor   (i32.add (local.get $keycursor) (i32.const 1)))
                    (local.set $pathcursor  (i32.add (local.get $pathcursor) (i32.const 1)))

                    (local.set $current_hash
                        (i32.add
                            (local.get $readed_value)
                            (local.get $pathcursor)
                        )
                    )

                    (if (i32.eq (local.get $char_code_$_) (local.get $readed_value)) 
                        (then
                            ;; lets end previous one and start new one
                            (br $done)
                        )
                    )

                    (if (i32.eq (local.get $char_code_:_) (local.get $readed_value))
                        (then
                            (if (i32.eq (local.get $desc_type_get/set))
                                (then
                                    (local.set $stepkey  (call $str_f (local.get $stepkey)))
                                    (local.set $parent   (call $desc  (local.get $parent) (local.get $stepkey)))
                                    (local.set $steppath (local.get $desc_keys_array_get/set))
                                )
                            )

                            (local.set $readed_value (local.get $char_code_._))
                            (local.set $finalizeFlag (i32.const 1))
                            (local.set $pathcursor   (i32.const 0))
                        )
                    )

                    (if (i32.eq (local.get $char_code_._) (local.get $readed_value))
                        (then
                            (local.set $str_fullpath (call $str_f (local.get $fullpath)))
                            (local.set $str_steppath (call $str_f (local.get $steppath)))

                            (local.set $object (call $egete (local.get $parent) (local.get $str_steppath)))
                            (call $esete (global.get $objects) (local.get $str_fullpath) (local.get $object))

                            (local.set $steppath  (call $array))
                            (local.set $keycursor (i32.const 0))
                        )
                    )

                    (call $iseti (local.get $stepkey) (local.get $keycursor) (local.get $readed_value))
                    (call $iseti (local.get $fullpath) (local.get $pathcursor) (local.get $readed_value))
                    
                    (br $read_charcodes_continously)
                )
            )
        )
    )
)
