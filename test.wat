(module
    (import "0" "0" (global (; 0 -> null ;) externref))
    (import "0" "1" (global (; 1 -> $self ;) externref))
    (import "0" "2" (global (; 2 -> $self.navigator ;) externref))
    (import "1" "0" (func (; 0 -> null ;) (param) (result)))
    (import "1" "1" (func (; 1 -> $void ;) (param) (result)))
    (import "1" "2" (func (; 1 -> $self.Navigator.prototype.gpu[get] ;) (param) (result)))
    
    (table (;0;) (export "ext") 4 65536 externref)
    (table (;1;) (export "fun") 4 65536 funcref)

    (elem (table 0) (i32.const 0) externref (ref.null extern) (global.get 1) (global.get 2))
    (elem (table 1) (i32.const 0) funcref (ref.null func) (ref.func 1) (ref.func 2))
)