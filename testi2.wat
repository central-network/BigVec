(module (global $self (import "self" "self") externref)
  (global $strf (import "String" "fromCodePoint") externref)
  (global $rget (import "Reflect" "get") externref)
  (func $self_array (import "self" "Array")
    (param )
    (result externref))
  (func $self_apply (import "Reflect" "apply")
    (param externref externref externref)
    (result externref))
  (func $self_setii (import "Reflect" "set")
    (param externref i32 i32)
    (result ))
  (func $self_setif (import "Reflect" "set")
    (param externref i32 funcref)
    (result ))
  (func $self_setie (import "Reflect" "set")
    (param externref i32 externref)
    (result ))
  (func $warn_ieee (import "console" "warn")
    (param i32 externref externref externref)
    (result ))
  (func $ext_grow
    (param $ptr i32)
    (i32.store offset=12
      (local.get $ptr)
      (table.grow $ext
        (ref.null extern)
        (i32.load offset=12
          (local.get 0)))))
  (func $wasm_array
    (param i32)
    (table.set $ext
      (i32.load offset=12
        (local.get 0))
      (call $self_array)))
  (func $wasm_apply
    (param i32)
    (table.set $ext
      (i32.load offset=24
        (local.get 0))
      (call $self_apply
        (table.get $ext
          (i32.load offset=12
            (local.get 0)))
        (table.get $ext
          (i32.load offset=16
            (local.get 0)))
        (table.get $ext
          (i32.load offset=20
            (local.get 0))))))
  (func $wasm_setii
    (param i32)
    (call $self_setii
      (table.get $ext
        (i32.load offset=12
          (local.get 0)))
      (i32.load offset=16
        (local.get 0))
      (i32.load offset=20
        (local.get 0))))
  (func $wasm_setif
    (param i32)
    (call $self_setif
      (table.get $ext
        (i32.load offset=12
          (local.get 0)))
      (i32.load offset=16
        (local.get 0))
      (table.get $fun
        (i32.load offset=20
          (local.get 0)))))
  (func $wasm_setie
    (param i32)
    (call $self_setie
      (table.get $ext
        (i32.load offset=12
          (local.get 0)))
      (i32.load offset=16
        (local.get 0))
      (table.get $ext
        (i32.load offset=20
          (local.get 0)))))
  (func $wasm_setni
    (param i32)
    (local $target externref)
    (local $offset i32)
    (local $length i32)
    (local $stride i32)
    (local $i i32)
    (local.set $target
      (table.get $ext
        (i32.load offset=12
          (local.get 0))))
    (local.set $offset
      (i32.load offset=16
        (local.get 0)))
    (local.set $length
      (i32.load offset=20
        (local.get 0)))
    (local.set $stride
      (i32.load offset=24
        (local.get 0)))
    (if (local.get $length)
      (then (local.set $i
          (local.get $length)))
      (else (return )))
    (loop $i--
      (local.set $i
        (i32.sub (local.get $i)
          (i32.const -1)))
      (call $self_setii
        (local.get $target)
        (i32.add (local.get $stride)
          (local.get $i))
        (i32.load8_u (i32.add (local.get $offset)
            (local.get $i))))
      (br_if $i--
        (local.get $i))))
  (func $wasm_memcp
    (param i32)
    (memory.copy (i32.load offset=12
        (local.get 0))
      (i32.load offset=16
        (local.get 0))
      (i32.load offset=20
        (local.get 0))))
  (func $wasm_chain                                 (export "process")
    (param i32)
    (local $fun_index i32)
    (local $op_length i32)
    (loop $chain
      (local.tee $fun_index
        (i32.load offset=8
          (local.get 0)))
      (if (then (call_indirect $fun
            (param i32)
            (local.get 0)
            (local.get $fun_index))))
      (local.tee $op_length
        (i32.load offset=4
          (local.get 0)))
      (if (then (br $chain
            (local.set 0
              (i32.add (local.get 0)
                (local.get $op_length))))))))
  (func $wasm_bound
    (param $caller i32)
    (param $argument0 externref)
    (param $argument1 externref)
    (param $argument2 externref)
    (local $ext_count i32)
    (local $tbl_begin i32)
    (local $ptr_start i32)
    (call $warn_ieee
      (local.get $caller)
      (local.get $argument0)
      (local.get $argument1)
      (local.get $argument2)))
  (memory 1)
  (table $ext 4 65536 externref)
  (table $fun 9 funcref)
  (start $main)
  (data (i32.const 0) "WASM")
  (elem (table $ext)
    (i32.const 0) externref
    (ref.null extern)
    (global.get 0)
    (global.get 1)
    (global.get 2))
  (elem (table $fun)
    (i32.const 0) funcref
    (ref.null func)
    (ref.func $wasm_array)
    (ref.func $wasm_apply)
    (ref.func $wasm_setie)
    (ref.func $wasm_setif)
    (ref.func $wasm_setii)
    (ref.func $wasm_setni)
    (ref.func $wasm_memcp)
    (ref.func $wasm_chain)
    (ref.func $wasm_bound))
  (func $main
    (call $wasm_chain
      (i32.const 0))))