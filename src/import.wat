(module
    (memory $memory 1 65536 shared)
    (table  $funcref 1 65536 funcref)
    (table  $externref 1 65536 externref)

    (data (i32.const 4) "\10")

    (export "#memory" (memory $memory))
    (export "#funcref" (table $funcref))
    (export "#externref" (table $externref))
)