
    (import "wasm" "idb.open" 
    (global $idb.open i32)) 
    (type   $idb.open (func (param externref externref i32) (result externref)))
    (func   $idb.open
    (type   $idb.open)
        (local.get 0)
        (local.get 1)
        (local.get 2)
        (call_indirect $funcref (type $idb.open) (gget $idb.open)) 
    )

    (import "wasm" "idb.get" 
    (global $idb.get i32)) 
    (type   $idb.get (func (param externref) (result externref)))
    (func   $idb.get
    (type   $idb.get)
        (local.get 0)
        (call_indirect $funcref (type $idb.get) (gget $idb.get)) 
    )

    (import "wasm" "idb.has" 
    (global $idb.has i32)) 
    (type   $idb.has (func (param externref) (result externref)))
    (func   $idb.has
    (type   $idb.has)
        (local.get 0)
        (call_indirect $funcref (type $idb.has) (gget $idb.has)) 
    )

    (import "wasm" "idb.set" 
    (global $idb.set i32)) 
    (type   $idb.set (func (param externref) (param externref) (result externref)))
    (func   $idb.set
    (type   $idb.set)
        (local.get 0)
        (local.get 1)
        (call_indirect $funcref (type $idb.set)(gget $idb.set)) 
    )

    (import "wasm" "idb.count" 
    (global $idb.count i32)) 
    (type   $idb.count (func (result externref)))
    (func   $idb.count
    (type   $idb.count)
        (call_indirect $funcref (type $idb.count) (gget $idb.count)) 
    )

    (import "wasm" "idb.del" 
    (global $idb.del i32)) 
    (type   $idb.del (func (param externref) (result externref)))
    (func   $idb.del
    (type   $idb.del)
        (local.get 0)
        (call_indirect $funcref (type $idb.del) (gget $idb.del)) 
    )

    (import "wasm" "idb.version" 
    (global $idb.version i32)) 
    (type   $idb.version (func (result i32)))
    (func   $idb.version
    (type   $idb.version)
        (call_indirect $funcref (type $idb.version) (gget $idb.version)) 
    )

