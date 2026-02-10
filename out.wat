
    (module
        (import "self" "self"           (global $self externref))
        (import "Array" "of"            (func $array (param externref externref) (result externref)))
        (import "Reflect" "set"         (func $set (param externref i32 i32)))
        (import "Reflect" "get"         (func $get (param externref externref) (result externref)))
        (import "Reflect" "apply"       (func $apply (param externref externref externref) (result externref)))
        (import "String" "fromCharCode" (global $strf externref))

        ;; (import "console" "log"         (func $logi (param i32)))
        ;; (import "console" "log"         (func $loge (param externref)))
        (import "console" "warn"         (func $warni3 (param externref i32 i32 i32)))

        (memory 1)

        (func $keys
            (local $keys_length i32)
            (local $keys_count  i32)
            (local $keys_index  i32)
            
            (local $key_length  i32)
            (local $key_index   i32)

            (local $data_index  i32)
            (local $data_value  i32)
            
            (local $i           i32)
            (local $ptr*        i32)
            (local $key_string  externref)
            (local $apply_args  externref)

            (local.set $apply_args  (call $array (ref.null extern) (ref.null extern)))
            (local.set $keys_length (i32.load16_u offset=0 (i32.const 8)))
            (local.set $keys_count  (i32.load16_u offset=2 (i32.const 8)))
            (local.set $ptr*        (i32.const 12))

            (loop $keys
                (local.set $key_length  (i32.load8_u offset=0 (local.get $ptr*)))                
                (local.set $key_index   (i32.load8_u offset=1 (local.get $ptr*)))                
                (local.set $data_index  (i32.const 0))

                (loop $at
                    (local.set $data_value (i32.load8_u offset=2 (local.get $ptr*)))                
                    (call $set (local.get $apply_args) (local.get $data_index) (local.get $data_value))
                    (local.set $ptr* (i32.add (i32.const 1) (local.get $ptr*))) 
                    (local.set $data_index (i32.add (i32.const 1) (local.get $data_index))) 
                    (br_if $at (i32.lt_u (local.get $data_index) (local.get $key_length)))
                )

                (local.set $ptr* (i32.add (i32.const 2) (local.get $ptr*))) 
                (local.set $keys_index (i32.add (i32.const 1) (local.get $keys_index)))  
                (local.set $key_string (call $apply (global.get $strf) (ref.null extern) (local.get $apply_args)))
                (table.set $self (local.get $key_index) (local.get $key_string))

                (br_if $keys (i32.lt_u (local.get $keys_index) (local.get $keys_count)))
            )
        )

        (func $funcs
            (local $super externref)
            (local $key externref)
            (local $id i32)

            (local.set $super
                (call $get 
                    (table.get (i32.const 1))
                    (table.get (i32.const 17))
                )
            )

            (local.set $id (i32.const 2))
            (local.set $key (table.get $self (i32.const 7)))
            (table.set $self (local.get $id) (call $get (local.get $super) (local.get $key)))

            (local.set $id (i32.const 3))
            (local.set $key (table.get $self (i32.const 24)))
            (table.set $self (local.get $id) (call $get (local.get $super) (local.get $key)))

            (local.set $super
                (call $get 
                    (table.get (i32.const 1))
                    (table.get (i32.const 19))
                )
            )

            (local.set $id (i32.const 4))
            (local.set $key (table.get $self (i32.const 12)))
            (table.set $self (local.get $id) (call $get (local.get $super) (local.get $key)))

            (local.set $id (i32.const 5))
            (local.set $key (table.get $self (i32.const 13)))
            (table.set $self (local.get $id) (call $get (local.get $super) (local.get $key)))
        )

        (func $apply_extref 
            (param $func        i32)
            (param $this        i32)
            (param $arg0        i32)
            (param $arg1        i32)
            (result       externref)

            (call $apply 
                (table.get $self (local.get $func)) 
                (table.get $self (local.get $this)) 
                (call $array
                    (table.get $self (local.get $arg0))
                    (table.get $self (local.get $arg1))
                )
            )
        )

        (func $pathwalk
            (local $count       i32)
            (local $i           i32)
            (local $ptr*        i32)
            (local $ext#  externref)
            
            (local $func        i32)
            (local $this        i32)
            (local $arg0        i32)
            (local $arg1        i32)

            (local $output_idx  i32)
            (local $import_ext  i32)
            (local $import_fun  i32)
            (local $reserved_2  i32)

            (local.set $count   (i32.load offset=194 (i32.const 8)))
            (local.set $ptr*    (i32.const 210))

            (loop $at
                (local.set $func (i32.load16_u offset=0 (local.get $ptr*)))
                (local.set $this (i32.load16_u offset=2 (local.get $ptr*)))
                (local.set $arg0 (i32.load16_u offset=4 (local.get $ptr*)))
                (local.set $arg1 (i32.load16_u offset=6 (local.get $ptr*)))

                (local.set $output_idx (i32.load16_u offset=8 (local.get $ptr*)))
                (local.set $import_ext (i32.load16_u offset=10 (local.get $ptr*)))
                (local.set $import_fun (i32.load16_u offset=12 (local.get $ptr*)))
                (local.set $reserved_2 (i32.load16_u offset=14 (local.get $ptr*)))

                (call $warni3
                    (table.get (local.get $arg1))
                    (local.get $output_idx)
                    (local.get $import_ext)
                    (local.get $import_fun)
                )

                (local.set $ext# (call $apply_extref (local.get $func) (local.get $this) (local.get $arg0) (local.get $arg1)))
                (table.set $self (local.get $output_idx) (local.get $ext#))
                (local.set $ptr* (i32.add (local.get $ptr*) (i32.const 16)))
                
                (local.set $i (i32.add (i32.const 1) (local.get $i))) 
                (br_if $at (i32.lt_u (local.get $i) (local.get $count)))
            )
        )

        (func $main
            (call $keys)
            (call $funcs)
            (call $pathwalk)
            
            (; $loge 
                (call $apply
                    (table.get $self (i32.const 4))
                    (table.get $self (i32.const 5))
                    (call $array
                        (call $apply
                            (table.get $self (i32.const 2))
                            (table.get $self (i32.const 0))
                            (call $array
                                (call $apply
                                    (table.get $self (i32.const 3))
                                    (table.get $self (i32.const 0))
                                    (call $array
                                        (table.get $self (i32.const 1))
                                        (table.get $self (i32.const 14))
                                    )
                                )
                                (table.get $self (i32.const 8))
                            )
                        )
                        (table.get $self (i32.const 0))
                    )
                )
            ;)
        )
        
        (table $self 36 externref)

        (elem (i32.const 0) externref (ref.null extern) (global.get 0))
        (data (i32.const 0) "\00\00\00\00\00\00\00\00\90\00\13\00\03\06\6c\6f\67\03\07\67\65\74\03\08\73\65\74\04\09\64\61\74\61\04\0a\68\72\65\66\04\0b\73\65\6c\66\04\0c\62\69\6e\64\04\0d\63\61\6c\6c\04\0e\6e\61\6d\65\06\0f\6c\65\6e\67\74\68\07\10\63\6f\6e\73\6f\6c\65\07\11\52\65\66\6c\65\63\74\08\12\6c\6f\63\61\74\69\6f\6e\08\13\46\75\6e\63\74\69\6f\6e\09\14\70\72\6f\74\6f\74\79\70\65\0b\15\45\76\65\6e\74\54\61\72\67\65\74\0c\16\4d\65\73\73\61\67\65\45\76\65\6e\74\10\17\61\64\64\45\76\65\6e\74\4c\69\73\74\65\6e\65\72\18\18\67\65\74\4f\77\6e\50\72\6f\70\65\72\74\79\44\65\73\63\72\69\70\74\6f\72\00\00\00\02\00\00\00\00\00\00\00\0b\00\00\00\00\00\00\00\02\00\00\00\01\00\15\00\19\00\00\00\00\00\00\00\02\00\00\00\19\00\14\00\1a\00\00\00\00\00\00\00\02\00\00\00\1a\00\17\00\1b\00\00\00\00\00\00\00\02\00\00\00\01\00\16\00\1c\00\00\00\00\00\00\00\02\00\00\00\1c\00\14\00\1d\00\00\00\00\00\00\00\03\00\00\00\1d\00\09\00\1e\00\00\00\00\00\00\00\02\00\00\00\1e\00\07\00\1f\00\00\00\00\00\00\00\02\00\00\00\01\00\10\00\20\00\00\00\00\00\00\00\02\00\00\00\20\00\06\00\21\00\00\00\00\00\00\00\02\00\00\00\01\00\12\00\22\00\00\00\00\00\00\00\02\00\00\00\22\00\0a\00\23\00\01\00\00\00\00\00")

        (start $main)
    )
    