
    (import "self" "wasm" (global $wasm externref))
    (import "wasm" "#funcref"  (table $funcref 1 65536 funcref))
    (import "wasm" "#externref" (table $externref 1 65536 externref))
