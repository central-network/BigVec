(module
  (import "self" "self"                        (global $self                                            externref))
  (import "self" "Array"                       (func $self.Array<>ext                                   (param) (result externref)))
  (import "String" "fromCharCode"              (global $self.String.fromCharCode                        externref))
  (import "Reflect" "set"                      (func $self.Reflect.set<ext.i32.i32>                     (param externref i32 i32) (result)))
  (import "Reflect" "set"                      (func $self.Reflect.set<ext.i32.ext>                     (param externref i32 externref) (result)))
  (import "Reflect" "get"                      (func $self.Reflect.get<ext.ext>ext                      (param externref externref) (result externref)))
  (import "Reflect" "construct"                (func $self.Reflect.construct<ext.ext>ext                (param externref externref) (result externref)))
  (import "Reflect" "apply"                    (func $self.Reflect.apply<ext.ext.ext>ext                (param externref externref externref) (result externref)))
  (import "Reflect" "getOwnPropertyDescriptor" (func $self.Reflect.getOwnPropertyDescriptor<ext.ext>ext (param externref externref) (result externref)))




  (global $wat4wasm (mut externref) (ref.null extern))

  (table $wat4wasm 24 externref)

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
      (block $decodeText/4:2
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 4))
        (local.set $length (i32.const 2))
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
        (table.set $wat4wasm (i32.const 9)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; id
        ))
      )
      (block $decodeText/6:5
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 6))
        (local.set $length (i32.const 5))
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
        (table.set $wat4wasm (i32.const 10)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; entry
        ))
      )
      (block $decodeText/11:10
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 11))
        (local.set $length (i32.const 10))
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
        (table.set $wat4wasm (i32.const 11)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; activation
        ))
      )
      (block $decodeText/21:10
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 21))
        (local.set $length (i32.const 10))
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
        (table.set $wat4wasm (i32.const 12)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; navigation
        ))
      )
      (block $decodeText/31:8
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 31))
        (local.set $length (i32.const 8))
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
        (table.set $wat4wasm (i32.const 13)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; location
        ))
      )
      (block $decodeText/39:6
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 39))
        (local.set $length (i32.const 6))
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
        (table.set $wat4wasm (i32.const 14)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; origin
        ))
      )
      (block $decodeText/45:11
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 45))
        (local.set $length (i32.const 11))
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
        (table.set $wat4wasm (i32.const 15)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; postMessage
        ))
      )
      (block $decodeText/56:9
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 56))
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
        (table.set $wat4wasm (i32.const 16)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; prototype
        ))
      )
      (block $decodeText/65:6
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 65))
        (local.set $length (i32.const 6))
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
        (table.set $wat4wasm (i32.const 17)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; Worker
        ))
      )
      (block $decodeText/71:3
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 71))
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
        (table.set $wat4wasm (i32.const 18)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; get
        ))
      )
      (block $decodeText/74:9
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 74))
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
        (table.set $wat4wasm (i32.const 19)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; onmessage
        ))
      )
      (block $decodeText/83:3
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 83))
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
        (table.set $wat4wasm (i32.const 20)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; set
        ))
      )
      (block $decodeText/86:4
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 86))
        (local.set $length (i32.const 4))
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
        (table.set $wat4wasm (i32.const 21)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; data
        ))
      )
      (block $decodeText/90:12
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 90))
        (local.set $length (i32.const 12))
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
        (table.set $wat4wasm (i32.const 22)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; MessageEvent
        ))
      )
      (block $decodeText/102:16
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 102))
        (local.set $length (i32.const 16))
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
        (table.set $wat4wasm (i32.const 23)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; initM ... Event
        ))
      )
    )
    (block $ontextready


      (block $self.MessageEvent.prototype.initMessageEvent<ext>
        (table.set $wat4wasm (i32.const 1)
          (call $self.Reflect.get<ext.ext>ext
            (call $self.Reflect.get<ext.ext>ext
              (call $self.Reflect.get<ext.ext>ext
                (global.get $self)
                (table.get $wat4wasm (i32.const 22));; MessageEvent
                ;; MessageEvent
              )
              (table.get $wat4wasm (i32.const 16));; prototype
              ;; prototype
            )
            (table.get $wat4wasm (i32.const 23));; initM ... Event
            ;; initMessageEvent
          )
      ))


      (block $self.MessageEvent.prototype.data/get
        (table.set $wat4wasm (i32.const 2)
          (call $self.Reflect.get<ext.ext>ext
            (call $self.Reflect.getOwnPropertyDescriptor<ext.ext>ext
              (call $self.Reflect.get<ext.ext>ext
                (call $self.Reflect.get<ext.ext>ext
                  (global.get $self)
                  (table.get $wat4wasm (i32.const 22));; MessageEvent
                  ;; MessageEvent
                )
                (table.get $wat4wasm (i32.const 16));; prototype
                ;; prototype
              )
              (table.get $wat4wasm (i32.const 21));; data
              ;; data
            )
            (table.get $wat4wasm (i32.const 18));; get
            ;; get
          )
      ))


      (block $self.Worker.prototype.onmessage/set
        (table.set $wat4wasm (i32.const 3)
          (call $self.Reflect.get<ext.ext>ext
            (call $self.Reflect.getOwnPropertyDescriptor<ext.ext>ext
              (call $self.Reflect.get<ext.ext>ext
                (call $self.Reflect.get<ext.ext>ext
                  (global.get $self)
                  (table.get $wat4wasm (i32.const 17));; Worker
                  ;; Worker
                )
                (table.get $wat4wasm (i32.const 16));; prototype
                ;; prototype
              )
              (table.get $wat4wasm (i32.const 19));; onmessage
              ;; onmessage
            )
            (table.get $wat4wasm (i32.const 20));; set
            ;; set
          )
      ))


      (block $self.Worker.prototype.onmessage/get
        (table.set $wat4wasm (i32.const 4)
          (call $self.Reflect.get<ext.ext>ext
            (call $self.Reflect.getOwnPropertyDescriptor<ext.ext>ext
              (call $self.Reflect.get<ext.ext>ext
                (call $self.Reflect.get<ext.ext>ext
                  (global.get $self)
                  (table.get $wat4wasm (i32.const 17));; Worker
                  ;; Worker
                )
                (table.get $wat4wasm (i32.const 16));; prototype
                ;; prototype
              )
              (table.get $wat4wasm (i32.const 19));; onmessage
              ;; onmessage
            )
            (table.get $wat4wasm (i32.const 18));; get
            ;; get
          )
      ))


      (block $self.Worker.prototype.postMessage<ext>
        (table.set $wat4wasm (i32.const 5)
          (call $self.Reflect.get<ext.ext>ext
            (call $self.Reflect.get<ext.ext>ext
              (call $self.Reflect.get<ext.ext>ext
                (global.get $self)
                (table.get $wat4wasm (i32.const 17));; Worker
                ;; Worker
              )
              (table.get $wat4wasm (i32.const 16));; prototype
              ;; prototype
            )
            (table.get $wat4wasm (i32.const 15));; postMessage
            ;; postMessage
          )
      ))


      (block $self.location.origin<ext>
        (table.set $wat4wasm (i32.const 6)
          (call $self.Reflect.get<ext.ext>ext
            (call $self.Reflect.get<ext.ext>ext
              (global.get $self)
              (table.get $wat4wasm (i32.const 13));; location
              ;; location
            )
            (table.get $wat4wasm (i32.const 14));; origin
            ;; origin
          )
      ))


      (block $self.location<ext>
        (table.set $wat4wasm (i32.const 7)
          (call $self.Reflect.get<ext.ext>ext
            (global.get $self)
            (table.get $wat4wasm (i32.const 13));; location
            ;; location
          )
      ))


      (block $self.navigation.activation.entry.id<ext>
        (table.set $wat4wasm (i32.const 8)
          (call $self.Reflect.get<ext.ext>ext
            (call $self.Reflect.get<ext.ext>ext
              (call $self.Reflect.get<ext.ext>ext
                (call $self.Reflect.get<ext.ext>ext
                  (global.get $self)
                  (table.get $wat4wasm (i32.const 12));; navigation
                  ;; navigation
                )
                (table.get $wat4wasm (i32.const 11));; activation
                ;; activation
              )
              (table.get $wat4wasm (i32.const 10));; entry
              ;; entry
            )
            (table.get $wat4wasm (i32.const 9));; id
            ;; id
          )
      ))

    )


    ;; restore zero heap value
    (i32.store (; stack stack ;))
    (nop)
  )


  (data $wat4wasm "\76\00\00\00\69\64\65\6e\74\72\79\61\63\74\69\76\61\74\69\6f\6e\6e\61\76\69\67\61\74\69\6f\6e\6c\6f\63\61\74\69\6f\6e\6f\72\69\67\69\6e\70\6f\73\74\4d\65\73\73\61\67\65\70\72\6f\74\6f\74\79\70\65\57\6f\72\6b\65\72\67\65\74\6f\6e\6d\65\73\73\61\67\65\73\65\74\64\61\74\61\4d\65\73\73\61\67\65\45\76\65\6e\74\69\6e\69\74\4d\65\73\73\61\67\65\45\76\65\6e\74")

  (memory $wat4wasm 1)

  (start $wat4wasm)
)