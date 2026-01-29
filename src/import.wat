(module
    (memory $memory 1 65536 shared)
    (table  $funcref 1 65536 funcref)
    (table  $externref 1 65536 externref)
    (table  $global 1 65536 externref)

    (export "memory" (memory $memory))
    (export "funcref" (table $funcref))
    (export "externref" (table $externref))
    (export "global" (table $global))
)