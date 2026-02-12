(module
  (import "self" "self"             (global $self externref))
  (import "String" "fromCodePoint"  (global $self_String_fromCodePoint externref))
  (import "Reflect" "get"           (global $self_Reflect_get externref))

  (import "self" "Array"            (func $self_array (param) (result externref)))
  (import "Reflect" "set"           (func $self_set_eii (param externref i32 i32) (result)))
  (import "Reflect" "set"           (func $self_set_eie (param externref i32 externref) (result)))
  (import "Reflect" "set"           (func $self_set_eif (param externref i32 funcref) (result)))
  (import "Reflect" "apply"         (func $self_apply (param externref externref externref) (result externref)))

  (;CHAIN_DATA;)

  (table $externref 4 65536 externref)
  (elem (table $externref) (i32.const 1) externref (global.get 0) (global.get 1) (global.get 2))

  (table $funcref 7 funcref)
  (elem (table $funcref) (i32.const 1)
    $wasm_array               ;; 1
    $wasm_set_eii             ;; 2
    $wasm_set_eie             ;; 3
    $wasm_set_eif             ;; 4
    $wasm_apply               ;; 5
    $copy                     ;; 6
  )

  (global $ptr (mut i32) (i32.const 0))

  (func $wasm_array
    (i32.store offset=12 (global.get $ptr) 
        (table.grow $externref (call $self_array) (i32.const 1))
    )
  )
  
  (func $wasm_set_eii
    (call $self_set_eii
        (table.get $externref (i32.load offset=12 (global.get $ptr)))
        (i32.load offset=16 (global.get $ptr))
        (i32.load offset=20 (global.get $ptr))
    )
  )

  (func $wasm_set_eie
    (call $self_set_eie
        (table.get $externref (i32.load offset=12 (global.get $ptr)))
        (i32.load offset=16 (global.get $ptr))                       
        (table.get $externref (i32.load offset=20 (global.get $ptr))) 
    )
  )
  
  (func $wasm_set_eif
    (call $self_set_eif
        (table.get $externref (i32.load offset=12 (global.get $ptr)))
        (i32.load offset=16 (global.get $ptr))
        (table.get $funcref (i32.load offset=20 (global.get $ptr)))
    )
  )

  (func $wasm_apply
    (i32.store offset=24 (global.get $ptr) 
        (table.grow $externref 
            (call $self_apply
                (table.get $externref (i32.load offset=12 (global.get $ptr))) 
                (table.get $externref (i32.load offset=16 (global.get $ptr))) 
                (table.get $externref (i32.load offset=20 (global.get $ptr))) 
            )
            (i32.const 1)
        )
    )
  )

  (func $copy
    (memory.copy 
        (i32.load offset=16 (global.get $ptr)) ;; dst
        (i32.load offset=12 (global.get $ptr)) ;; src
        (i32.load offset=20 (global.get $ptr)) ;; len
    )
  )

  (func $start 
    (local $size i32)
    (local $func_idx i32)

    (loop $chain
      (local.tee $func_idx (i32.load offset=8 (global.get $ptr)))
      (if (then (call_indirect $funcref (local.get $func_idx))))

      (local.tee $size (i32.load offset=4 (global.get $ptr)))
      (global.set $ptr (i32.add (global.get $ptr)))

      (br_if $chain (local.get $size))
    )
  )
  
  (start $start) 
)
