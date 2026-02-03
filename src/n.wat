(module
    (import "self" "getter" (func $getter (param externref) (result externref)))
    (import "self" "listen" (func $listen (param externref externref funcref) (result)))
    (import "self" "log" (func $log (param externref) (result)))
    (import "Reflect" "apply" (func $ref_apply (param externref externref externref) (result)))

    (table $apply 4 10 funcref)
    (table $self 4 10 externref)
    
    (export "funcref" (table $apply))
    (export "externref" (table $self))

    (elem $funcs funcref
        (ref.func $getter)
        (ref.func $listen)
        (ref.func $log)
    )

    (main $assign
        (table.set $apply (i32.const 1) (ref.func $getter))
        (table.set $apply (i32.const 2) (ref.func $listen))
        (table.set $apply (i32.const 3) (ref.func $log))
        (table.set $self (i32.const 1) (self))
        (table.set $self (i32.const 2) (text "message"))
    )
)