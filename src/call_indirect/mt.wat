
    (import "wasm" "mt.fork" 
    (global $mt.fork i32)) 
    (type   $mt.fork (func (param i32) (result i32)))
    (func   $mt.fork
    (type   $mt.fork)
        (local.get 0)
        (call_indirect $funcref (type $mt.fork) (global.get $mt.fork)) 
    )

    (import "wasm" "mt.ref" 
    (global $mt.ref i32)) 
    (type   $mt.ref (func (param i32) (result externref)))
    (func   $mt.ref
    (type   $mt.ref)
        (local.get 0)
        (call_indirect $funcref (type $mt.ref) (global.get $mt.ref)) 
    )

    (import "wasm" "mt.close" 
    (global $mt.close i32)) 
    (type   $mt.close (func (param i32) (result)))
    (func   $mt.close
    (type   $mt.close)
        (local.get 0)
        (call_indirect $funcref (type $mt.close) (global.get $mt.close)) 
    )
