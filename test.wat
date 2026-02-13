(module
  (import "console" "log" (func $test (param i32)))
  (start $start) 
  (func $start
    (call $test (i32.const 0))
  ) 
)