(module
    (import "0" "0" (func (; 0 -> null ;) (param) (result)))
    (import "0" "1" (func (; 1 -> self.console.log/value ;) (param externref externref externref externref) (result)))
    (import "0" "2" (func (; 2 -> self.console.warn/value ;) (param externref externref) (result)))
    (import "0" "3" (func (; 3 -> self.MessageEvent.prototype.data/get ;) (param externref) (result externref)))
    (import "0" "4" (func (; 4 -> self.EventTarget.prototype.addEventListener/value ;) (param externref externref funcref) (result)))
    (import "1" "0" (global (; 0 -> null ;) externref))
    (import "1" "1" (global (; 1 -> self.location/value ;) externref))
    (import "1" "2" (global (; 2 -> self.location.href/get ;) externref))
    (import "1" "3" (global (; 3 -> self.length/get ;) externref))
    (import "1" "4" (global (; 4 -> "any string literal" ;) externref))
    (import "1" "5" (global (; 5 -> "hello world" ;) externref))
    
    (table (;0;) (export "funcref") 0 65536 funcref)
    (table (;1;) (export "externref") 0 65536 externref)

    (elem (table 0) (i32.const 0) funcref (ref.func 0) (ref.func 1) (ref.func 2) (ref.func 3) (ref.func 4))
    (elem (table 1) (i32.const 0) externref (global.get 0) (global.get 1) (global.get 2) (global.get 3) (global.get 4) (global.get 5))
)