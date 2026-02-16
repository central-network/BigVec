(module
    (import "wasm" "ext" (table $ext 0 65536 externref))
    (import "wasm" "fun" (table $fun 0 65536 funcref))
)