(module
  (import "self" "self"                        (global $self                                            externref))
  (import "Math" "random"                      (func $self.Math.random<>f32                             (param) (result f32)))
  (import "self" "Array"                       (func $self.Array<>ext                                   (param) (result externref)))
  (import "Array" "of"                         (func $self.Array.of<>ext                                (param) (result externref)))
  (import "Math" "max"                         (func $self.Math.max<f32.f32>f32                         (param f32 f32) (result f32)))
  (import "String" "fromCharCode"              (global $self.String.fromCharCode                        externref))
  (import "Array" "of"                         (func $self.Array.of<f32>ext                             (param f32) (result externref)))
  (import "Array" "of"                         (func $self.Array.of<i32>ext                             (param i32) (result externref)))
  (import "console" "log"                      (func $self.console.log<ext>                             (param externref) (result)))
  (import "console" "warn"                     (func $self.console.warn<ext>                            (param externref) (result)))
  (import "console" "log"                      (func $self.console.log<ext.i32>                         (param externref i32) (result)))
  (import "Number" "isNaN"                     (func $self.Number.isNaN<ext>i32                         (param externref) (result i32)))
  (import "Object" "is"                        (func $self.Object.is<ext.f32>i32                        (param externref f32) (result i32)))
  (import "Array" "of"                         (func $self.Array.of<ext>ext                             (param externref) (result externref)))
  (import "Array" "isArray"                    (func $self.Array.isArray<ext>i32                        (param externref) (result i32)))
  (import "Reflect" "set"                      (func $self.Reflect.set<ext.i32.i32>                     (param externref i32 i32) (result)))
  (import "Number" "isSafeInteger"             (func $self.Number.isSafeInteger<i32>i32                 (param i32) (result i32)))
  (import "Object" "is"                        (func $self.Object.is<ext.ext>i32                        (param externref externref) (result i32)))
  (import "URL" "revokeObjectURL"              (func $self.URL.revokeObjectURL<ext>                     (param externref) (result)))
  (import "Reflect" "set"                      (func $self.Reflect.set<ext.i32.ext>                     (param externref i32 externref) (result)))
  (import "Reflect" "ownKeys"                  (func $self.Reflect.ownKeys<ext>ext                      (param externref) (result externref)))
  (import "Array" "fromAsync"                  (func $self.Array.fromAsync<ext>ext                      (param externref) (result externref)))
  (import "Reflect" "get"                      (func $self.Reflect.get<ext.ext>ext                      (param externref externref) (result externref)))
  (import "Object" "fromEntries"               (func $self.Object.fromEntries<ext>ext                   (param externref) (result externref)))
  (import "URL" "createObjectURL"              (func $self.URL.createObjectURL<ext>ext                  (param externref) (result externref)))
  (import "Reflect" "set"                      (func $self.Reflect.set<ext.ext.ext>i32                  (param externref externref externref) (result i32)))
  (import "Reflect" "getPrototypeOf"           (func $self.Reflect.getPrototypeOf<ext>ext               (param externref) (result externref)))
  (import "Reflect" "construct"                (func $self.Reflect.construct<ext.ext>ext                (param externref externref) (result externref)))
  (import "Reflect" "apply"                    (func $self.Reflect.apply<ext.ext.ext>ext                (param externref externref externref) (result externref)))
  (import "Reflect" "getOwnPropertyDescriptor" (func $self.Reflect.getOwnPropertyDescriptor<ext.ext>ext (param externref externref) (result externref)))


















  (global $wat4wasm (mut externref) (ref.null extern))

  (table $wat4wasm 18 externref)

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
      (block $decodeText/4:4
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 4))
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
        (table.set $wat4wasm (i32.const 1)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; name
        ))
      )
      (block $decodeText/8:4
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 8))
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
        (table.set $wat4wasm (i32.const 2)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; test
        ))
      )
      (block $decodeText/12:13
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 12))
        (local.set $length (i32.const 13))
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
            (local.get $arguments) ;; bye bye world
        ))
      )
      (block $decodeText/25:11
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 25))
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
        (table.set $wat4wasm (i32.const 4)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; hello world
        ))
      )

      (block $decodeText/36:9
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 36))
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
        (table.set $wat4wasm (i32.const 11)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; undefined
        ))
      )
      (block $decodeText/45:3
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 45))
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
        (table.set $wat4wasm (i32.const 12)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; NaN
        ))
      )
      (block $decodeText/48:5
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 48))
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
        (table.set $wat4wasm (i32.const 13)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; floor
        ))
      )
      (block $decodeText/53:4
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 53))
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
        (table.set $wat4wasm (i32.const 14)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; Math
        ))
      )
      (block $decodeText/57:6
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 57))
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
        (table.set $wat4wasm (i32.const 15)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; Object
        ))
      )
      (block $decodeText/63:11
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 63))
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
        (table.set $wat4wasm (i32.const 16)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; ArrayBuffer
        ))
      )
      (block $decodeText/74:11
        (local.set $viewAt (i32.const 0))
        (local.set $offset (i32.const 74))
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
        (table.set $wat4wasm (i32.const 17)
          (call $self.Reflect.apply<ext.ext.ext>ext
            (local.get $textDecoder.decode)
            (local.get $textDecoder)
            (local.get $arguments) ;; MediaSource
        ))
      )
    )
    (block $ontextready


      (block $self.MediaSource<ext>
        (table.set $wat4wasm (i32.const 5)
          (call $self.Reflect.get<ext.ext>ext
            (global.get $self)
            (table.get $wat4wasm (i32.const 17));; MediaSource
            ;; MediaSource
          )
      ))


      (block $self.ArrayBuffer<ext>
        (table.set $wat4wasm (i32.const 6)
          (call $self.Reflect.get<ext.ext>ext
            (global.get $self)
            (table.get $wat4wasm (i32.const 16));; ArrayBuffer
            ;; ArrayBuffer
          )
      ))


      (block $self.Object<ext>
        (table.set $wat4wasm (i32.const 7)
          (call $self.Reflect.get<ext.ext>ext
            (global.get $self)
            (table.get $wat4wasm (i32.const 15));; Object
            ;; Object
          )
      ))


      (block $self.Math.floor<ext>
        (table.set $wat4wasm (i32.const 8)
          (call $self.Reflect.get<ext.ext>ext
            (call $self.Reflect.get<ext.ext>ext
              (global.get $self)
              (table.get $wat4wasm (i32.const 14));; Math
              ;; Math
            )
            (table.get $wat4wasm (i32.const 13));; floor
            ;; floor
          )
      ))




      (block $self.NaN<ext>
        (table.set $wat4wasm (i32.const 9)
          (call $self.Reflect.get<ext.ext>ext
            (global.get $self)
            (table.get $wat4wasm (i32.const 12));; NaN
            ;; NaN
          )
      ))


      (block $self.undefined<ext>
        (table.set $wat4wasm (i32.const 10)
          (call $self.Reflect.get<ext.ext>ext
            (global.get $self)
            (table.get $wat4wasm (i32.const 11));; undefined
            ;; undefined
          )
      ))

    )


    ;; restore zero heap value
    (i32.store (; stack stack ;))
    (nop)
  )


  (data $wat4wasm "\55\00\00\00\6e\61\6d\65\74\65\73\74\62\79\65\20\62\79\65\20\77\6f\72\6c\64\68\65\6c\6c\6f\20\77\6f\72\6c\64\75\6e\64\65\66\69\6e\65\64\4e\61\4e\66\6c\6f\6f\72\4d\61\74\68\4f\62\6a\65\63\74\41\72\72\61\79\42\75\66\66\65\72\4d\65\64\69\61\53\6f\75\72\63\65")

  (memory $wat4wasm 1)

  (start $wat4wasm)
)