
    (import "wasm" "uuid.forEach" 
    (global $uuid.forEach i32)) 
    (type   $uuid.forEach (func (param externref externref) (result)))
    (func   $uuid.forEach
    (type   $uuid.forEach)
        (local.get 0)
        (local.get 1)
        (call_indirect $funcref (type $uuid.forEach) (global.get $uuid.forEach)) 
    )

    (import "wasm" "uuid.has" 
    (global $uuid.has i32)) 
    (type   $uuid.has (func (param externref) (result i32)))
    (func   $uuid.has
    (type   $uuid.has)
        (local.get 0)
        (call_indirect $funcref (type $uuid.has) (global.get $uuid.has)) 
    )

    (import "wasm" "uuid.indexOf" 
    (global $uuid.indexOf i32)) 
    (type   $uuid.indexOf (func (param externref) (result i32)))
    (func   $uuid.indexOf
    (type   $uuid.indexOf)
        (local.get 0)
        (call_indirect $funcref (type $uuid.indexOf) (global.get $uuid.indexOf)) 
    )

    (import "wasm" "uuid.push" 
    (global $uuid.push i32)) 
    (type   $uuid.push (func (param externref) (result i32)))
    (func   $uuid.push
    (type   $uuid.push)
        (local.get 0)
        (call_indirect $funcref (type $uuid.push) (global.get $uuid.push)) 
    )

    (import "wasm" "uuid.count" 
    (global $uuid.count i32)) 
    (type   $uuid.count (func (result i32)))
    (func   $uuid.count
    (type   $uuid.count)
        (call_indirect $funcref (type $uuid.count) (global.get $uuid.count)) 
    )

    (import "wasm" "uuid.at" 
    (global $uuid.at i32)) 
    (type   $uuid.at (func (param i32) (result externref)))
    (func   $uuid.at
    (type   $uuid.at)
        (local.get 0)
        (call_indirect $funcref (type $uuid.at) (global.get $uuid.at)) 
    )
