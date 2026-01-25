(module







  (func $unreferenced_by_user)





  (elem $wat4wasm declare func $inline $unreferenced_by_user)







  (memory $wat4wasm 1)


  (func $inline
    (local $a i32)
    (local.set $a (i32.const 2))
  )



)