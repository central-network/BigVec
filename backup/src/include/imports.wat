
    (import "idb" "get"     (func $idb.get (param i32) (result externref)))
    (import "idb" "open"    (func $idb.open (param externref externref i32) (result externref)))
    (import "uuid" "get"    (func $uuid.get))