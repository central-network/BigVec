
    (module
        (import "self" "self"           (global externref))
		(import "Reflect" "get"         (global externref))
		(import "String" "fromCharCode" (global externref))
        
        (import "Reflect" "apply"       (func $apply (param externref externref externref) (result externref)))
        (import "Reflect" "set"         (func $isete (param externref i32 externref) (result)))
        (import "Reflect" "set"         (func $isetf (param externref i32 funcref) (result)))
        (import "Reflect" "set"         (func $iseti (param externref i32 i32) (result)))
        (import "self" "Array"          (func $array (param) (result externref)))

        (import "console" "log"         (func $loge (param externref)))
        (import "console" "warn"        (func $warne (param externref)))
        (import "console" "warn"        (func $warni (param i32)))
        (import "console" "error"       (func $logi (param i32)))

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

            (local.set $apply_args  (call $array))
            (local.set $keys_length (i32.load16_u offset=0 (i32.const 8)))
            (local.set $keys_count  (i32.load16_u offset=2 (i32.const 8)))
            (local.set $ptr*        (i32.const 12))

            (loop $keys
                (local.set $key_length  (i32.load8_u offset=0 (local.get $ptr*)))                
                (local.set $key_index   (i32.load8_u offset=1 (local.get $ptr*)))                
                (local.set $data_index  (i32.const 0))

                (loop $at
                    (local.set $data_value (i32.load8_u offset=2 (local.get $ptr*)))                
                    (call $iseti (local.get $apply_args) (local.get $data_index) (local.get $data_value))
                    (local.set $ptr* (i32.add (i32.const 1) (local.get $ptr*))) 
                    (local.set $data_index (i32.add (i32.const 1) (local.get $data_index))) 
                    (br_if $at (i32.lt_u (local.get $data_index) (local.get $key_length)))
                )

                (local.set $ptr* (i32.add (i32.const 2) (local.get $ptr*))) 
                (local.set $keys_index (i32.add (i32.const 1) (local.get $keys_index)))  
                (local.set $key_string 
                    (call $apply 
                        (table.get $self (i32.const 3)) 
                        (table.get $self (i32.const 0)) 
                        (local.get $apply_args)
                    )
                )

                (table.set $self 
                    (local.get $key_index) 
                    (local.get $key_string)
                )

                (br_if $keys (i32.lt_u (local.get $keys_index) (local.get $keys_count)))
            )
        )

        (func $apply_extref 
            (param $func        i32)
            (param $this        i32)
            (param $arg0        i32)
            (param $arg1        i32)
            (result       externref)
            (local $args  externref)
            
            (local.set $args (call $array))

            (call $isete (local.get $args) (i32.const 0) (table.get $self (local.get $arg0)))
            (call $isete (local.get $args) (i32.const 1) (table.get $self (local.get $arg1)))

            (call_indirect $wasm 
                (param externref externref externref) (result externref)

                (table.get $self (local.get $func)) 
                (table.get $self (local.get $this)) 
                (local.get $args)

                (i32.const 1)
            )
        )

        (global $imports (mut externref) (ref.null extern))

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

            (local $imports_ext externref)
            (local $imports_fun externref)

            (local.set $count   (i32.load offset=288 (i32.const 8)))
            (local.set $ptr*    (i32.const 304))
            
            (global.set $imports (call $array))

            (call $isete (global.get $imports) (i32.const 0) (local.tee $imports_ext (call $array)))
            (call $isete (global.get $imports) (i32.const 1) (local.tee $imports_fun (call $array)))

            (loop $at
                (local.set $func (i32.load16_u offset=0 (local.get $ptr*)))
                (local.set $this (i32.load16_u offset=2 (local.get $ptr*)))
                (local.set $arg0 (i32.load16_u offset=4 (local.get $ptr*)))
                (local.set $arg1 (i32.load16_u offset=6 (local.get $ptr*)))

                (local.set $output_idx (i32.load16_u offset=8 (local.get $ptr*)))
                (local.set $reserved_2 (i32.load16_u offset=14 (local.get $ptr*)))

                (if (ref.is_null 
                        (local.tee $ext# (table.get $self (local.get $output_idx)))
                    )
                    (then
                        (local.set $ext# 
                            (call $apply_extref 
                                (local.get $func) 
                                (local.get $this) 
                                (local.get $arg0) 
                                (local.get $arg1)
                            )
                        )
                    )
                )
                (table.set $self (local.get $output_idx) (local.get $ext#))
                
                (local.tee $import_ext (i32.load16_u offset=10 (local.get $ptr*)))
                (if (then (call $isete (local.get $imports_ext) (local.get $import_ext) (local.get $ext#))))
                
                (local.tee $import_fun (i32.load16_u offset=12 (local.get $ptr*)))
                (if (then (call $isete (local.get $imports_fun) (local.get $import_fun) (local.get $ext#))))

                (local.set $i       (i32.add    (i32.const 1) (local.get $i))) 
                (local.set $ptr*    (i32.add    (local.get $ptr*) (i32.const 16)))
                (br_if $at          (i32.lt_u   (local.get $i) (local.get $count)))
            )

            (call $isete (local.get $imports_ext) (i32.const 0) (table.get $self (i32.const 0)))
            (call $isete (local.get $imports_ext) (i32.const 1) (table.get $self (i32.const 1)))
            (call $isete (local.get $imports_fun) (i32.const 0) (table.get $self (i32.const 6)))
        )

        (global $argv_level_0 (mut externref) (ref.null extern))
        (global $argv_level_1 (mut externref) (ref.null extern))

        (func $argv_builder_iseti
            (param $offset i32)
        )

        (func $instantiate
            (param $source      externref)
            (param $imports     externref)
            (result             externref)
            (local $argv        externref)

            (call_indirect $wasm
                (param) (result externref)
                (i32.const 5)
            )
            (local.set $argv)

            (call_indirect $wasm
                (param externref i32 externref) (result)
                
                (local.get $argv) 
                (i32.const 0) 
                (local.get 0)

                (i32.const 2)
            )

            (call_indirect $wasm
                (param externref i32 externref) (result)
                
                (local.get $argv) 
                (i32.const 1) 
                (local.get 1)

                (i32.const 2)
            )

            (call_indirect $wasm
                (param externref externref externref) (result externref)

                (table.get $self (i32.const 11))
                (table.get $self (i32.const 0))
                (local.get $argv)
                
                (i32.const 1)
            )
        )

        (func $buffers
            (local $byteOffset                    i32)
            (local $byteLength                    i32)
            (local $offsetByte                    i32)
            (local $bufferView              externref)
            (local $buffer                  externref)
            (local $apply_argv              externref)
            (local $construct_argv          externref)
            (local $self.Uint8Array         externref)
            (local $self.Reflect.construct  externref)

            (local.set $byteOffset (i32.const 868))
            (local.set $byteLength (i32.const 122))

            (local.set $apply_argv (call $array))
            (local.set $construct_argv (call $array))
            (local.set $self.Uint8Array (table.get $self (i32.const 9)))
            (local.set $self.Reflect.construct (table.get $self (i32.const 5)))

            (call $iseti (local.get $apply_argv) (i32.const 0) (local.get $byteLength))
            (call $isete (local.get $construct_argv) (i32.const 0) (local.get $self.Uint8Array))
            (call $isete (local.get $construct_argv) (i32.const 1) (local.get $apply_argv))

            (local.set $bufferView
                (call $apply
                    (local.get $self.Reflect.construct)
                    (ref.null extern)
                    (local.get $construct_argv)
                )
            )

            (loop $read
                (local.tee $byteLength (i32.sub (local.get $byteLength) (i32.const 1)))
                (local.set $offsetByte (i32.load8_u (i32.add (local.get $byteOffset))))

                (call_indirect $wasm
                    (param externref i32 i32) (result) 

                    (local.get $bufferView)
                    (local.get $byteLength) 
                    (local.get $offsetByte) 
                    
                    (i32.const 4)
                )
                    
                (br_if $read (local.get $byteLength))
            )

            (call $warne (global.get $imports))
            (call $warne (local.get $bufferView))
            (call $warne 
                (call $instantiate
                    (local.get $bufferView)
                    (global.get $imports)
                )
            )
        )

        (func $main#
            (call $keys)
            (call $pathwalk)
            (call $buffers)
        )

        (func $func_4
            (call $logi (call $**))
            (call $## (i32.const 22))
        )

        (func $func_5
            (call $warni (call $**))
        )

        (func $+- loop i32.const 0 i32.const 16 i32.atomic.rmw.add i32.load 
        (call_indirect) i32.const 4 i32.const 1 i32.atomic.rmw.sub br_if 0 end)        
        
        (func $** (result i32) (i32.load (i32.const 12)))
        (func $## (param i32) (i32.store (i32.const 12) (local.get 0)))

        (start $+-)

        
        (table $wasm 6 funcref)
        (table $self 80 externref)

        (elem (table $self) (i32.const 0) externref (ref.null extern) (global.get 0) (global.get 1) (global.get 2))
        (elem (table $wasm) (i32.const 0) funcref 
        
        
        
        
        (ref.null func)
        (ref.func $apply)
        
        (ref.func $isete)
        
        (ref.func $isetf)
        
        (ref.func $iseti)
        
        (ref.func $array)
        )
        
        (data (i32.const 0) "\00\00\00\00\00\00\00\00\dd\00\1b\00\03\0e\6c\6f\67\03\0f\67\65\74\04\10\62\69\6e\64\04\11\63\61\6c\6c\04\12\64\61\74\61\04\13\68\72\65\66\04\14\73\65\6c\66\06\15\53\74\72\69\6e\67\06\16\4d\65\6d\6f\72\79\06\17\62\75\66\66\65\72\07\18\52\65\66\6c\65\63\74\07\19\63\6f\6d\70\69\6c\65\07\1a\65\78\70\6f\72\74\73\07\1b\63\6f\6e\73\6f\6c\65\08\1c\46\75\6e\63\74\69\6f\6e\08\1d\49\6e\73\74\61\6e\63\65\08\1e\6c\6f\63\61\74\69\6f\6e\09\1f\63\6f\6e\73\74\72\75\63\74\09\20\70\72\6f\74\6f\74\79\70\65\0a\21\55\69\6e\74\38\41\72\72\61\79\0b\22\69\6e\73\74\61\6e\74\69\61\74\65\0b\23\57\65\62\41\73\73\65\6d\62\6c\79\0b\24\45\76\65\6e\74\54\61\72\67\65\74\0c\25\66\72\6f\6d\43\68\61\72\43\6f\64\65\0c\26\4d\65\73\73\61\67\65\45\76\65\6e\74\10\27\61\64\64\45\76\65\6e\74\4c\69\73\74\65\6e\65\72\18\28\67\65\74\4f\77\6e\50\72\6f\70\65\72\74\79\44\65\73\63\72\69\70\74\6f\72\00\03\00\00\00\04\00\00\00\23\00\00\00\00\00\00\00\02\00\00\00\01\00\18\00\29\00\00\00\00\00\00\00\02\00\00\00\29\00\0f\00\02\00\00\00\00\00\00\00\02\00\00\00\01\00\15\00\2a\00\00\00\00\00\00\00\02\00\00\00\2a\00\25\00\03\00\00\00\00\00\00\00\02\00\00\00\29\00\28\00\04\00\00\00\00\00\00\00\02\00\00\00\29\00\1f\00\05\00\00\00\00\00\00\00\02\00\00\00\01\00\1c\00\06\00\00\00\00\00\00\00\02\00\00\00\06\00\10\00\07\00\00\00\00\00\00\00\02\00\00\00\06\00\11\00\08\00\00\00\00\00\00\00\02\00\00\00\01\00\21\00\09\00\00\00\00\00\00\00\02\00\00\00\01\00\23\00\2b\00\00\00\00\00\00\00\02\00\00\00\2b\00\19\00\0a\00\00\00\00\00\00\00\02\00\00\00\2b\00\22\00\0b\00\00\00\00\00\00\00\02\00\00\00\2b\00\1d\00\2c\00\00\00\00\00\00\00\02\00\00\00\2c\00\20\00\2d\00\00\00\00\00\00\00\04\00\00\00\2d\00\1a\00\2e\00\00\00\00\00\00\00\02\00\00\00\2e\00\0f\00\2f\00\00\00\00\00\00\00\02\00\00\00\2b\00\16\00\30\00\00\00\00\00\00\00\02\00\00\00\30\00\20\00\31\00\00\00\00\00\00\00\04\00\00\00\31\00\17\00\32\00\00\00\00\00\00\00\02\00\00\00\32\00\0f\00\33\00\00\00\00\00\00\00\02\00\00\00\01\00\1b\00\34\00\00\00\00\00\00\00\02\00\00\00\34\00\0e\00\35\00\00\00\00\00\00\00\07\00\08\00\34\00\00\00\36\00\00\00\01\00\00\00\02\00\00\00\01\00\26\00\37\00\00\00\00\00\00\00\02\00\00\00\37\00\20\00\38\00\00\00\00\00\00\00\04\00\00\00\38\00\12\00\39\00\00\00\00\00\00\00\02\00\00\00\39\00\0f\00\3a\00\00\00\00\00\00\00\07\00\08\00\39\00\00\00\3b\00\00\00\02\00\00\00\02\00\00\00\01\00\1e\00\3c\00\00\00\00\00\00\00\02\00\00\00\3c\00\13\00\3d\00\02\00\00\00\00\00\02\00\00\00\01\00\24\00\3e\00\00\00\00\00\00\00\02\00\00\00\3e\00\20\00\3f\00\00\00\00\00\00\00\02\00\00\00\3f\00\27\00\40\00\00\00\00\00\00\00\07\00\08\00\3f\00\00\00\41\00\00\00\03\00\00\00\00\00\00\00\00\61\73\6d\01\00\00\00\01\04\01\60\00\00\02\2e\07\01\30\01\30\03\6f\00\01\30\01\31\03\6f\00\01\30\01\32\03\6f\00\01\31\01\30\00\00\01\31\01\31\00\00\01\31\01\32\00\00\01\31\01\33\00\00\04\0d\02\6f\01\03\80\80\04\70\01\04\80\80\04\07\0d\02\03\65\78\74\01\00\03\66\75\6e\01\01\09\1c\02\06\00\41\00\0b\6f\03\23\00\0b\23\01\0b\23\02\0b\02\01\41\00\0b\00\04\00\01\02\03")
        
        (elem (table $wasm) (i32.const 4) funcref (ref.func $func_4) (ref.func $func_5))

        (data (i32.const  0) "\10\00\00\00\01\00\00\00\1b\00\00\00\1a\00\00\00")
        (data (i32.const 16) "\04\00\00\00\02\00\00\00\00\00\00\00\00\00\00\00")
        (data (i32.const 32) "\05\00\00\00\03\00\00\00\00\00\00\00\00\00\00\00")
    )
    