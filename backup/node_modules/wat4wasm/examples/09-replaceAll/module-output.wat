(module
  (import "self" "self"           (global $self                             externref))
  (import "console" "log"         (func $self.console.log<f32>              (param f32) (result)))
  (import "console" "log"         (func $self.console.log<i32>              (param i32) (result)))
  (import "console" "log"         (func $self.console.log<i64>              (param i64) (result)))
  (import "self" "Array"          (func $self.Array<>ext                    (param) (result externref)))
  (import "self" "Object"         (func $self.Object<>ext                   (param) (result externref)))
  (import "console" "log"         (func $self.console.log<fun>              (param funcref) (result)))
  (import "String" "fromCharCode" (global $self.String.fromCharCode         externref))
  (import "console" "log"         (func $self.console.log<ext>              (param externref) (result)))
  (import "Reflect" "set"         (func $self.Reflect.set<ext.i32.i32>      (param externref i32 i32) (result)))
  (import "Reflect" "set"         (func $self.Reflect.set<ext.i32.ext>      (param externref i32 externref) (result)))
  (import "Reflect" "get"         (func $self.Reflect.get<ext.ext>ext       (param externref externref) (result externref)))
  (import "Reflect" "construct"   (func $self.Reflect.construct<ext.ext>ext (param externref externref) (result externref)))
  (import "Reflect" "apply"       (func $self.Reflect.apply<ext.ext.ext>ext (param externref externref externref) (result externref)))


  (func $replace
    (local $this f32)

    (local.get 0)
    (call $self.console.log<f32>)

    (global.get $self)
    (call $self.console.log<ext>)

    (ref.null extern)
    (call $self.console.log<ext>)

    (ref.null func)
    (call $self.console.log<fun>)

    (i32.const 1)
    (call $self.console.log<i32>)

    (i32.const 0)
    (call $self.console.log<i32>)

    (table.get $wat4wasm (i32.const 2)) ;; $self.NaN<ext>

    (call $self.console.log<ext>)

    (f32.const nan)
    (call $self.console.log<f32>)

    (call $self.Array<>ext)
    (call $self.console.log<ext>)

    (call $self.Object<>ext)
    (call $self.console.log<ext>)

    (table.get $wat4wasm (i32.const 1)) ;; $self.undefined<ext>

    (call $self.console.log<ext>)


    (call $self.Reflect.apply<ext.ext.ext>ext
      (global.get $self.String.fromCharCode)
      (global.get $self)
      (global.get $self)
    )

    (call $self.console.log<ext>)

    (local.get $this)
    (call $self.console.log<f32>)

    (global.get $wat4wasm)
    (call $self.console.log<ext>)

    (table.get $wat4wasm (i32.const 0))
    (call $self.console.log<ext>)

    (table.grow $wat4wasm (ref.null extern) (i32.const 0))
    (drop)

    (i32.const 2)
    (call $self.console.log<i32>)

    (f32.const -2)
    (call $self.console.log<f32>)

    (f32.const -2.2)
    (call $self.console.log<f32>)

    (f32.const +2.2)
    (call $self.console.log<f32>)

    (i64.const +2)
    (call $self.console.log<i64>)
  )

  (global $wat4wasm (mut externref) (ref.null extern))

  (table $wat4wasm 5 externref)

  (elem $wat4wasm declare func)


  (func $wat4wasm
    (local $textDecoder externref)
    (local $textDecoder.decode externref)
    (local $Uint8Array externref)
    (local $arguments externref)
    (local $arrayBufferView externref)
    (local $viewAt i32)
    (local $offset i32)
    (local $length i32)
    (block $prepare
      (local.set $textDecoder
        (call $self.Reflect.construct<ext.ext>ext
          (call $self.Reflect.get<ext.ext>ext
            (global.get $self)

            (block (; "TextDecoder" ;)
              (result externref)
              (global.set $wat4wasm (call $self.Array<>ext))

              (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 0) (i32.const 84))
              (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 1) (i32.const 101))
              (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 2) (i32.const 120))
              (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 3) (i32.const 116))
              (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 4) (i32.const 68))
              (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 5) (i32.const 101))
              (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 6) (i32.const 99))
              (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 7) (i32.const 111))
              (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 8) (i32.const 100))
              (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 9) (i32.const 101))
              (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 10) (i32.const 114))

              (call $self.Reflect.apply<ext.ext.ext>ext
                (global.get $self.String.fromCharCode)
                (ref.null extern)
                (global.get $wat4wasm)
              )
              ;; stacked

              (global.set $wat4wasm (ref.null extern))
              ;; cleared
            )

          )
          (global.get $self)
        )
      )
      (local.set $textDecoder.decode
        (call $self.Reflect.get<ext.ext>ext
          (local.get $textDecoder)

          (block (; "decode" ;)
            (result externref)
            (global.set $wat4wasm (call $self.Array<>ext))

            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 0) (i32.const 100))
            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 1) (i32.const 101))
            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 2) (i32.const 99))
            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 3) (i32.const 111))
            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 4) (i32.const 100))
            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 5) (i32.const 101))

            (call $self.Reflect.apply<ext.ext.ext>ext
              (global.get $self.String.fromCharCode)
              (ref.null extern)
              (global.get $wat4wasm)
            )
            ;; stacked

            (global.set $wat4wasm (ref.null extern))
            ;; cleared
          )

        )
      )
      (local.set $Uint8Array
        (call $self.Reflect.get<ext.ext>ext
          (global.get $self)

          (block (; "Uint8Array" ;)
            (result externref)
            (global.set $wat4wasm (call $self.Array<>ext))

            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 0) (i32.const 85))
            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 1) (i32.const 105))
            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 2) (i32.const 110))
            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 3) (i32.const 116))
            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 4) (i32.const 56))
            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 5) (i32.const 65))
            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 6) (i32.const 114))
            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 7) (i32.const 114))
            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 8) (i32.const 97))
            (call $self.Reflect.set<ext.i32.i32> (global.get $wat4wasm) (i32.const 9) (i32.const 121))

            (call $self.Reflect.apply<ext.ext.ext>ext
              (global.get $self.String.fromCharCode)
              (ref.null extern)
              (global.get $wat4wasm)
            )
            ;; stacked

            (global.set $wat4wasm (ref.null extern))
            ;; cleared
          )

        )
      )
    )
    ;;secure zero heap for memory.init
    (i32.const 0)
    (i32.load (i32.const 0))
    ;; offset and value stacked now
    (block $oninit
      (block $decodeText/4:3
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 4))
        (local.set $length (i32.const 3))
        (local.set $arguments (call $self.Array<>ext))

        (call $self.Reflect.set<ext.i32.i32>
          (local.get $arguments) (i32.const 0) (local.get $length)
        )
        (local.set $arrayBufferView
          (call $self.Reflect.construct<ext.ext>ext
            (local.get $Uint8Array)
            (local.get $arguments)
          )
        )
        (loop $length--
          (if (local.get $length)
            (then
              (memory.init $wat4wasm
                (i32.const 0)
                (local.get $offset)
                (i32.const 1)
              )
              (call $self.Reflect.set<ext.i32.i32>
                (local.get $arrayBufferView)
                (local.get $viewAt)
                (i32.load8_u (i32.const 0))
              )
              (local.set $viewAt (i32.add (local.get $viewAt) (i32.const 1)))
              (local.set $offset (i32.add (local.get $offset) (i32.const 1)))
              (local.set $length (i32.sub (local.get $length) (i32.const 1)))
              (br $length--)
            )
          )
        )
        (local.set $arguments (call $self.Array<>ext))
        (call $self.Reflect.set<ext.i32.ext>
          (local.get $arguments)
          (i32.const 0)
          (local.get $arrayBufferView)
        )
        (table.set $wat4wasm (i32.const 3)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; NaN
        ))
      )
      (block $decodeText/7:9
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 7))
        (local.set $length (i32.const 9))
        (local.set $arguments (call $self.Array<>ext))

        (call $self.Reflect.set<ext.i32.i32>
          (local.get $arguments) (i32.const 0) (local.get $length)
        )
        (local.set $arrayBufferView
          (call $self.Reflect.construct<ext.ext>ext
            (local.get $Uint8Array)
            (local.get $arguments)
          )
        )
        (loop $length--
          (if (local.get $length)
            (then
              (memory.init $wat4wasm
                (i32.const 0)
                (local.get $offset)
                (i32.const 1)
              )
              (call $self.Reflect.set<ext.i32.i32>
                (local.get $arrayBufferView)
                (local.get $viewAt)
                (i32.load8_u (i32.const 0))
              )
              (local.set $viewAt (i32.add (local.get $viewAt) (i32.const 1)))
              (local.set $offset (i32.add (local.get $offset) (i32.const 1)))
              (local.set $length (i32.sub (local.get $length) (i32.const 1)))
              (br $length--)
            )
          )
        )
        (local.set $arguments (call $self.Array<>ext))
        (call $self.Reflect.set<ext.i32.ext>
          (local.get $arguments)
          (i32.const 0)
          (local.get $arrayBufferView)
        )
        (table.set $wat4wasm (i32.const 4)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; undefined
        ))
      )
    )
    (block $ontextready


      (block $self.undefined<ext>
        (table.set $wat4wasm (i32.const 1)
          (call $self.Reflect.get<ext.ext>ext
            (global.get $self)
            (table.get $wat4wasm (i32.const 4));; undefined
            ;; undefined
          )
      ))


      (block $self.NaN<ext>
        (table.set $wat4wasm (i32.const 2)
          (call $self.Reflect.get<ext.ext>ext
            (global.get $self)
            (table.get $wat4wasm (i32.const 3));; NaN
            ;; NaN
          )
      ))

    )


    ;; restore zero heap value
    (i32.store (; stack stack ;))
    (nop)

    (call $replace)
  )


  (data $wat4wasm "\10\00\00\00\4e\61\4e\75\6e\64\65\66\69\6e\65\64")

  (memory $wat4wasm 1)



  (start $wat4wasm)
)