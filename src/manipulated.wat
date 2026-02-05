
(module
    (import "self" "self"                           (global $self externref))
    (import "String" "fromCodePoint"                (global $strf externref))
    (import "Reflect" "getOwnPropertyDescriptor"    (func $desc (param externref externref) (result externref)))
    (import "Reflect" "get"                         (func $eget (param externref externref) (result externref)))
    (import "Reflect" "get"                         (func $iget (param externref i32) (result externref)))
    (import "Reflect" "set"                         (func $tset (param externref externref externref)))
    (import "Reflect" "set"                         (func $eset (param externref i32 externref)))
    (import "Reflect" "set"                         (func $fset (param externref i32 funcref)))
    (import "Reflect" "set"                         (func $iset (param externref i32 i32)))
    (import "Reflect" "apply"                       (func $apply (param externref externref externref) (result externref)))
    (import "self" "Array"                          (func $array (result externref)))
    (import "console" "log"                          (func $log (param externref)))

    (global $texts (mut externref) (ref.null extern))
    (global $externref (mut externref) (ref.null extern))

    (memory 1)

    (func $main
        (local externref externref externref externref)
        (local $funcref      externref)
        (local $imports      externref)
        (local $args         externref)
        (local $cursor       i32)
        (local $length       i32)
        (local $end          i32)
        (local $point_idx    i32)
        (local $func_idx     i32)
        (local $code_point   i32)
        (local $temp         externref)
        (local $interset.wasm externref)
        (local $directed.wasm externref)

        (block $create_local_variables
            (local.set $funcref     (call $array))
            (global.set $externref  (call $array))
            (local.set $imports     (call $array))
            (global.set $texts      (call $array))

            (call $eset (local.get $imports) (i32.const 0) (local.get $funcref))
            (call $eset (local.get $imports) (i32.const 1) (global.get $externref))
            (call $eset (local.get $imports) (i32.const 2) (global.get $texts))

            (call $fset (local.get $funcref)   (i32.const 0) (ref.null func))
            (call $eset (global.get $externref) (i32.const 0) (global.get $self))
        )

        (block $decode_string_literals
            (local.set $args (call $array))
            
            (block $decode/26 (; $texts[26] = "get" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 3))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 227)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 26)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/25 (; $texts[25] = "log" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 3))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 224)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 25)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/24 (; $texts[24] = "wasm" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 4))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 220)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 24)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/23 (; $texts[23] = "then" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 4))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 216)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 23)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/22 (; $texts[22] = "call" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 4))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 212)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 22)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/21 (; $texts[21] = "bind" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 4))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 208)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 21)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/20 (; $texts[20] = "href" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 4))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 204)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 20)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/19 (; $texts[19] = "data" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 4))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 200)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 19)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/18 (; $texts[18] = "Promise" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 7))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 193)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 18)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/17 (; $texts[17] = "Reflect" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 7))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 186)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 17)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/16 (; $texts[16] = "exports" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 7))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 179)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 16)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/15 (; $texts[15] = "compile" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 7))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 172)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 15)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/14 (; $texts[14] = "console" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 7))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 165)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 14)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/13 (; $texts[13] = "message" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 7))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 158)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 13)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/12 (; $texts[12] = "instance" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 8))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 150)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 12)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/11 (; $texts[11] = "location" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 8))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 142)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 11)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/10 (; $texts[10] = "prototype" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 9))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 133)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 10)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/9 (; $texts[9] = "construct" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 9))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 124)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 9)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/8 (; $texts[8] = "prototype" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 9))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 115)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 8)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/7 (; $texts[7] = "prototype" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 9))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 106)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 7)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/6 (; $texts[6] = "Uint8Array" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 10))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 96)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 6)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/5 (; $texts[5] = "instantiate" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 11))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 85)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 5)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/4 (; $texts[4] = "WebAssembly" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 11))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 74)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 4)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/3 (; $texts[3] = "EventTarget" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 11))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 63)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 3)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/2 (; $texts[2] = "MessageEvent" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 12))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 51)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 2)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/1 (; $texts[1] = "addEventListener" ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 16))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 35)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 1)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

        
            (block $decode/0 (; $texts[0] = "Özgür Fırat Özpol.." ;)
                (local.set $point_idx   (i32.const 0))
                (local.set $cursor      (i32.const 0))
                (local.set $end         (i32.const 35))
                (local.set $length      (i32.const 0))

                (loop $codePointAt
                    (if (i32.lt_u (local.get $length) (local.get $end))
                        (then
                            (local.set $cursor (i32.add (local.get $length) (i32.const 0)))
                            (local.set $code_point (i32.load8_u (local.get $cursor)))

                            (if (i32.eq (local.get $code_point) (i32.const 128))
                                (then
                                    (local.set $code_point  (i32.load offset=1 (local.get $cursor)))
                                    (local.set $length      (i32.add (local.get $length) (i32.const 4)))
                                )
                            )

                            (local.set $length (i32.add (local.get $length) (i32.const 1)))

                            (call $iset
                                (local.get $args)
                                (local.get $point_idx)
                                (local.get $code_point)
                            )

                            (local.set $point_idx (i32.add (local.get $point_idx) (i32.const 1)))

                            (br $codePointAt)
                        )
                    )
                )

                (call $eset
                    (global.get $texts)
                    (i32.const 0)
                    (call $apply (global.get $strf) (ref.null extern) (local.get $args))
                )
            )

            (memory.fill (i32.const 0) (i32.const 0) (i32.const 230))
            (data.drop $text)
        )

        (block $settle_externref_items
            (local.set $args (call $array))
            
            (block $self
                (local.set 0 (global.get $self))
      
                (block $self.console
                    (local.set 1
                        (call $eget
                            (local.get 0)
                            (call $iget (global.get $texts) (i32.const 14))
                        )
                    )
      
                    (block $self.console.log
                        (local.set 2
                            (call $eget
                                (local.get 1)
                                (call $iget (global.get $texts) (i32.const 25))
                            )
                        )
      
                        (call $eset
                            (local.get $funcref)
                            (i32.const 1)
                            (local.get 2)
                        )
                    )
                )
      
                (block $self.MessageEvent
                    (local.set 1
                        (call $eget
                            (local.get 0)
                            (call $iget (global.get $texts) (i32.const 2))
                        )
                    )
      
                    (block $self.MessageEvent.prototype
                        (local.set 2
                            (call $eget
                                (local.get 1)
                                (call $iget (global.get $texts) (i32.const 10))
                            )
                        )
      
                        (block $self.MessageEvent.prototype.data/get
                            (local.set 3
                                (call $eget
                                    (call $desc (local.get 2) (call $iget (global.get $texts) (i32.const 19)))
                                    (call $iget (global.get $texts) (i32.const 26))
                                )
                            )
      
                            (call $eset
                                (local.get $funcref)
                                (i32.const 2)
                                (local.get 3)
                            )
                        )
                    )
                )
      
                (block $self.location
                    (local.set 1
                        (call $eget
                            (local.get 0)
                            (call $iget (global.get $texts) (i32.const 11))
                        )
                    )
      
                    (block $self.location.href
                        (local.set 2
                            (call $eget
                                (local.get 1)
                                (call $iget (global.get $texts) (i32.const 20))
                            )
                        )
      
                        (call $eset
                            (global.get $externref)
                            (i32.const 1)
                            (local.get 2)
                        )
                    )
                )
      
                (block $self.EventTarget
                    (local.set 1
                        (call $eget
                            (local.get 0)
                            (call $iget (global.get $texts) (i32.const 3))
                        )
                    )
      
                    (block $self.EventTarget.prototype
                        (local.set 2
                            (call $eget
                                (local.get 1)
                                (call $iget (global.get $texts) (i32.const 10))
                            )
                        )
      
                        (block $self.EventTarget.prototype.addEventListener
                            (local.set 3
                                (call $eget
                                    (local.get 2)
                                    (call $iget (global.get $texts) (i32.const 1))
                                )
                            )
      
                            (call $eset
                                (local.get $funcref)
                                (i32.const 3)
                                (local.get 3)
                            )
                        )
                    )
                )
            )
        )

        (block $caller_bound_functions
        
            (br_if $caller_bound_functions
                (i32.const 4)
                (i32.eqz (local.tee $func_idx))
            )

            (local.set $args (call $array))

            (local.set 0
                (call $eget
                    (global.get $strf)
                    (call $iget (global.get $texts) (i32.const 21))
                )
            )

            (local.set 1
                (call $eget
                    (global.get $strf)
                    (call $iget (global.get $texts) (i32.const 22))
                )
            )

            (loop $binding
                (local.set $func_idx (i32.sub (local.get $func_idx) (i32.const 1)))

                (call $eset
                    (local.get $args)
                    (i32.const 0)
                    (call $iget (local.get $funcref) (local.get $func_idx))
                )
                
                (call $eset
                    (local.get $funcref)
                    (local.get $func_idx)
                    (call $apply
                        (local.get 0)
                        (local.get 1)
                        (local.get $args)
                    )
                )

                (br_if $binding (local.get $func_idx))
            )
        )

        (block $cloning_wasm_source
            (local.set $args (call $array))

            (local.set 0 (call $iget (global.get $texts) (i32.const 17)))
            (local.set 0 (call $eget (global.get $self) (local.get 0)))

            (local.set 1 (call $iget (global.get $texts) (i32.const 9)))
            (local.set 1 (call $eget (local.get 0) (local.get 1)))

            (local.set 2 (call $iget (global.get $texts) (i32.const 6)))
            (local.set 2 (call $eget (global.get $self) (local.get 2)))
            
            (call $eset (local.get $args) (i32.const 0) (local.get 2) )

            (local.set $cursor (i32.const 467))
            (memory.init $interset_wasm (i32.const 0) (i32.const 0) (local.get $cursor))
            (data.drop $interset_wasm)

            (call $eset (local.get $args) (i32.const 1) (local.tee 3 (call $array)))
            (call $iset (local.get 3) (i32.const 0) (local.get $cursor))
            
            (local.set 4 (call $apply (local.get 1) (local.get 0) (local.get $args)))

            (loop $bufferize
                (if (local.tee $cursor (i32.sub (local.get $cursor) (i32.const 1)))
                    (then
                        (call $iset
                            (local.get 4)
                            (local.get $cursor)
                            (i32.load8_u (local.get $cursor))
                        )

                        (br $bufferize)
                    )
                )
            )

            (local.set $args (call $array))

            (call $eset
                (local.get $args)
                (i32.const 0)
                (local.get 4)
            )

            (call $eset
                (local.get $args)
                (i32.const 1)
                (local.get $imports)
            )
            
            (local.set 0 (call $eget (global.get $self) (call $iget (global.get $texts) (i32.const 4))))
            (local.set 1 (call $eget (local.get 0) (call $iget (global.get $texts) (i32.const 5))))

            (local.set 2 (call $iget (global.get $texts) (i32.const 18)))
            (local.set 2 (call $eget (global.get $self) (local.get 2)))

            (local.set 3 (call $eget (local.get 2) (call $iget (global.get $texts) (i32.const 10))))
            (local.set 3 (call $eget (local.get 3) (call $iget (global.get $texts) (i32.const 23))))

            (call $fset
                (local.tee 4 (call $array))
                (i32.const 0)
                (ref.func $oninstersetinstance)
            )
            
            (call $apply
                (local.get 3)
                (call $apply (local.get 1) (ref.null extern) (local.get $args))
                (local.get 4)
            )

            (drop)
        )
    )

    (elem funcref (ref.func $oninstersetinstance) (ref.func $ondirectedinstance))

    (func $ondirectedinstance
        (param $exports externref)
        (local.get 0)
        (call $eget (call $iget (global.get $texts) (i32.const 12)))
        (call $log)
    )

    (func $oninstersetinstance
        (param $exports externref)
        (param $instantiate externref)
        (param $arguments externref)
        (param $Uint8Array externref)
        (param $construct externref)
        (param $arrayargs externref)
        (param $source externref)
        (param $then externref)
        (param $callbackargs externref)
        (param $cursor i32)

        (local.set $instantiate
            (global.get $self)
            (call $eget (call $iget (global.get $texts) (i32.const 4)))
            (call $eget (call $iget (global.get $texts) (i32.const 5)))
        )

        (local.set $construct
            (global.get $self)
            (call $eget (call $iget (global.get $texts) (i32.const 17)))
            (call $eget (call $iget (global.get $texts) (i32.const 9)))
        )

        (local.set $Uint8Array
            (global.get $self)
            (call $eget (call $iget (global.get $texts) (i32.const 6)))
        )

        (local.set $cursor   (i32.const 235))
        (local.set $exports  (call $eget (local.get $exports) (call $iget (global.get $texts) (i32.const 12))))
        (local.set $exports  (call $eget (local.get $exports) (call $iget (global.get $texts) (i32.const 16))))

        (call $tset (global.get $self) (call $iget (global.get $texts) (i32.const 24)) (local.get $exports))

        (memory.init $directed_wasm (i32.const 0) (i32.const 0) (local.get $cursor))
        (data.drop $directed_wasm)

        (local.set $arrayargs (call $array))
        (local.set $arguments (call $array))

        (call $iset (local.get $arrayargs) (i32.const 0) (local.get $cursor))
        (call $eset (local.get $arguments) (i32.const 0) (local.get $Uint8Array))
        (call $eset (local.get $arguments) (i32.const 1) (local.get $arrayargs))

        (local.set $source
            (call $apply
                (local.get $construct)
                (ref.null extern)
                (local.get $arguments)
            )
        )

        (loop $bufferize
            (if (local.tee $cursor (i32.sub (local.get $cursor) (i32.const 1)))
                (then
                    (call $iset
                        (local.get $source)
                        (local.get $cursor)
                        (i32.load8_u (local.get $cursor))
                    )

                    (br $bufferize)
                )
            )
        )

        (local.set $then
            (global.get $self)
            (call $eget (call $iget (global.get $texts) (i32.const 18)))
            (call $eget (call $iget (global.get $texts) (i32.const 10)))
            (call $eget (call $iget (global.get $texts) (i32.const 23)))
        )

        (local.set $arguments (call $array))
        (call $eset (local.get $arguments) (i32.const 0) (local.get $source))
        (call $eset (local.get $arguments) (i32.const 1) (global.get $self))

        (local.set $instantiate
            (call $apply
                (local.get $instantiate)
                (ref.null extern)
                (local.get $arguments)
            )
        )

        (call $fset
            (local.tee $callbackargs (call $array))
            (i32.const 0)
            (ref.func $ondirectedinstance)
        )

        (call $apply
            (local.get $then)
            (local.get $instantiate)
            (local.get $callbackargs)
        )

        (drop)
    )

    (data $text (i32.const 0) "\80\d6\00\00\00\7a\67\80\fc\00\00\00\72\20\46\80\31\01\00\00\72\61\74\20\80\d6\00\00\00\7a\70\6f\6c\61\74\61\64\64\45\76\65\6e\74\4c\69\73\74\65\6e\65\72\4d\65\73\73\61\67\65\45\76\65\6e\74\45\76\65\6e\74\54\61\72\67\65\74\57\65\62\41\73\73\65\6d\62\6c\79\69\6e\73\74\61\6e\74\69\61\74\65\55\69\6e\74\38\41\72\72\61\79\70\72\6f\74\6f\74\79\70\65\70\72\6f\74\6f\74\79\70\65\63\6f\6e\73\74\72\75\63\74\70\72\6f\74\6f\74\79\70\65\6c\6f\63\61\74\69\6f\6e\69\6e\73\74\61\6e\63\65\6d\65\73\73\61\67\65\63\6f\6e\73\6f\6c\65\63\6f\6d\70\69\6c\65\65\78\70\6f\72\74\73\52\65\66\6c\65\63\74\50\72\6f\6d\69\73\65\64\61\74\61\68\72\65\66\62\69\6e\64\63\61\6c\6c\74\68\65\6e\77\61\73\6d\6c\6f\67\67\65\74")
    (data $interset_wasm "\00\61\73\6d\01\00\00\00\01\16\04\60\00\00\60\04\6f\6f\6f\6f\00\60\01\6f\01\6f\60\03\6f\6f\70\00\02\f5\01\21\01\30\01\30\00\00\01\30\01\31\00\01\01\30\01\32\00\02\01\30\01\33\00\03\01\31\01\30\03\6f\00\01\31\01\31\03\6f\00\01\32\01\30\03\6f\00\01\32\01\31\03\6f\00\01\32\01\32\03\6f\00\01\32\01\33\03\6f\00\01\32\01\34\03\6f\00\01\32\01\35\03\6f\00\01\32\01\36\03\6f\00\01\32\01\37\03\6f\00\01\32\01\38\03\6f\00\01\32\01\39\03\6f\00\01\32\02\31\30\03\6f\00\01\32\02\31\31\03\6f\00\01\32\02\31\32\03\6f\00\01\32\02\31\33\03\6f\00\01\32\02\31\34\03\6f\00\01\32\02\31\35\03\6f\00\01\32\02\31\36\03\6f\00\01\32\02\31\37\03\6f\00\01\32\02\31\38\03\6f\00\01\32\02\31\39\03\6f\00\01\32\02\32\30\03\6f\00\01\32\02\32\31\03\6f\00\01\32\02\32\32\03\6f\00\01\32\02\32\33\03\6f\00\01\32\02\32\34\03\6f\00\01\32\02\32\35\03\6f\00\01\32\02\32\36\03\6f\00\04\13\03\70\01\04\80\80\04\6f\01\02\80\80\04\6f\01\1b\80\80\04\07\21\03\07\66\75\6e\63\72\65\66\01\00\09\65\78\74\65\72\6e\72\65\66\01\01\07\74\65\78\74\72\65\66\01\02\09\6f\03\00\41\00\0b\04\00\01\02\03\06\01\41\00\0b\6f\02\23\00\0b\23\01\0b\06\02\41\00\0b\6f\1b\23\02\0b\23\03\0b\23\04\0b\23\05\0b\23\06\0b\23\07\0b\23\08\0b\23\09\0b\23\0a\0b\23\0b\0b\23\0c\0b\23\0d\0b\23\0e\0b\23\0f\0b\23\10\0b\23\11\0b\23\12\0b\23\13\0b\23\14\0b\23\15\0b\23\16\0b\23\17\0b\23\18\0b\23\19\0b\23\1a\0b\23\1b\0b\23\1c\0b\00\10\04\6e\61\6d\65\02\09\04\00\00\01\00\02\00\03\00")
    (data $directed_wasm "\00\61\73\6d\01\00\00\00\01\1a\05\60\01\6f\00\60\01\6f\01\6f\60\04\6f\6f\6f\6f\00\60\00\00\60\03\6f\6f\70\00\02\3f\03\04\77\61\73\6d\07\66\75\6e\63\72\65\66\01\70\01\04\80\80\04\04\77\61\73\6d\09\65\78\74\65\72\6e\72\65\66\01\6f\01\02\80\80\04\04\77\61\73\6d\07\74\65\78\74\72\65\66\01\6f\01\1b\80\80\04\03\03\02\00\03\08\01\01\09\05\01\01\00\01\00\0a\2c\02\18\00\d0\6f\20\00\41\02\11\01\00\41\00\25\02\41\01\25\01\41\01\11\02\00\0b\11\00\41\00\25\01\41\0d\25\02\d2\00\41\03\11\04\00\0b\00\47\04\6e\61\6d\65\01\12\02\00\09\6f\6e\6d\65\73\73\61\67\65\01\04\6d\61\69\6e\02\0c\02\00\01\00\05\65\76\65\6e\74\01\00\05\1e\03\00\07\66\75\6e\63\72\65\66\01\09\65\78\74\65\72\6e\72\65\66\02\07\74\65\78\74\72\65\66")

    (start $main)
)