(module
    (data $worker.wasm "wasm://worker.wat")
    (data $clock.wasm "wasm://clock.wat")
    (data $worker.js "file://worker.js")

    (table $ref 1 65536 externref)

    (global $module mut ext)
    (global $memory mut ext)
    (global $worker mut ext)
    (global $packet mut ext)

    (global $imports mut ext)
    (global $message mut ext)

    (global $PAGESIZE_INITIAL i32 i32(1))
    (global $PAGESIZE_MAXIMUM i32 i32(65536))
    (global $MEMORY_IS_SHARED i32 (true))

    (main $window
        (async
            (call $instantiate 
                (data.view $clock.wasm)
                (call $tee_self_imports)
            )
            (then $onclockinstance
                (param $instance <Instance>)
                (console $warn<ext> (global.get $imports))
                (console $log<ext.ext> (text "clock module instantiated!") (this))
            )
        )
    )

    (func $spwan
        (result <Promise>)

        (async.ext
            (call $compile (data.view $worker.wasm))
            (then $oncompile
                (param $module   <Module>)
                (result          <Memory>)

                (global.set $module (this))                
                (call $create_worker (data.href $worker.js))
            )
            (then $onmodule
                (param $worker   <Worker>)
                (result          <Object>)
                
                (global.set $worker (this))
                (call $settle_data (object))
            )
            (then $onpacket
                (param $packet   <Object>)
                
                (global.set $packet (this))
                (call $post_message (global.get $worker) (this))
            )
        )
    )

    (func $compile         
        (param $source           <Buffer>)
        (result                 <Promise>)

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $WebAssembly.compile)
            (null)
            (array $of<ext>ext (local.get $source))
        )
    )

    (func $instantiate         
        (param $source           <Buffer>)
        (param $imports          <Object>)
        (result                 <Promise>)

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $WebAssembly.instantiate)
            (null)
            (array $of<ext.ext>ext 
                (local.get $source) 
                (local.get $imports)
            )
        )
    )

    (func $post_message
        (param $worker           <Worker>)
        (param $packet           <Object>)

        (reflect $apply<ext.ext.ext>
            (ref.extern $Worker:postMessage)
            (this)
            (array $of<ext>ext (local.get $packet))
        )
    )

    (func $settle_data
        (param $data             <Object>)
        (result                  <Object>)

        (reflect $set<ext.ext.ext> (this) (text "module") (global.get $module))
        (reflect $set<ext.ext.ext> (this) (text "memory") (global.get $memory))

        (this)
    )

    (func $create_worker
        (param $script              <URL>)
        (result                  <Worker>)

        (reflect $construct<ext.ext>ext
            (ref.extern $Worker)
            (array $of<ext>ext (this))
        )
    )

    (func $tee_self_imports
        (result                  <Object>)
        (local $descriptor       <Object>)
        (local $memory           <Memory>)
        (local $buffer      <ArrayBuffer>)
        (local $dataView       <DataView>)
        (local $uInt8Array   <Uint8Array>)
        (local $int32Array   <Int32Array>)

        (if (i32.eqz (ref.is_null (global.get $imports)))
            (then (self) return)
        )

        (global.set $imports (object))
        (global.set $message (object))

        (local.set $descriptor
            (object $fromEntries<ext>ext
                (array $of<ext.ext.ext>ext
                    (array $of<ext.i32>ext (text "initial") (global.get $PAGESIZE_INITIAL))
                    (array $of<ext.i32>ext (text "maximum") (global.get $PAGESIZE_MAXIMUM))
                    (array $of<ext.i32>ext (text "shared")  (global.get $MEMORY_IS_SHARED))
                )
            )
        )

        (global.set $memory
            (reflect $construct<ext.ext>ext 
                (ref.extern $WebAssembly.Memory) 
                (array $of<ext>ext (local.get $descriptor))
            )
        )
        
        (local.set $buffer
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $WebAssembly.Memory:buffer[get])
                (global.get $memory)
                (array)
            )
        )

        (local.set $dataView
            (reflect $construct<ext.ext>ext
                (ref.extern $DataView)
                (array $of<ext>ext (local.get $buffer))
            )
        )

        (reflect $apply<ext.ext.ext>
            (ref.extern $DataView:setUint8)
            (local.get $dataView)
            (array $of<i32.i32>ext i32(4) i32(8))
        )

        (local.set $uInt8Array
            (reflect $construct<ext.ext>ext
                (ref.extern $Uint8Array)
                (array $of<ext>ext (local.get $buffer))
            )
        )

        (local.set $int32Array
            (reflect $construct<ext.ext>ext
                (ref.extern $Int32Array)
                (array $of<ext>ext (local.get $buffer))
            )
        )

        (reflect $set<ext.ext.ext> 
            (global.get $imports) 
            (text "shared_memory")
            (object $fromEntries<ext>ext
                (array $of<ext.ext.ext.ext.ext.ext.ext.ext.ext>ext
                    (array $of<ext.ext>ext (text "memory") (global.get $memory))
                    (array $of<ext.ext>ext (text "memory_buffer") (local.get $buffer))
                    (array $of<ext.ext>ext (text "memory_dataview") (local.get $dataView))
                    (array $of<ext.ext>ext (text "memory_uint8array") (local.get $uInt8Array))
                    (array $of<ext.ext>ext (text "memory_int32array") (local.get $int32Array))
                    (array $of<ext.i32>ext (text "memory_pagesize_initial") (global.get $PAGESIZE_INITIAL))
                    (array $of<ext.i32>ext (text "memory_pagesize_maximum") (global.get $PAGESIZE_MAXIMUM))
                    (array $of<ext.i32>ext (text "memory_buffer_length_initial") (i32.mul (global.get $PAGESIZE_INITIAL) i32(65536)))
                    (array $of<ext.i32>ext (text "memory_buffer_length_maximum") (i32.mul (global.get $PAGESIZE_MAXIMUM) i32(65536)))
                )
            )
        )

        (reflect $set<ext.ext.ext> (global.get $message) (text "memory") (global.get $memory))
        (reflect $set<ext.ext.ext> (global.get $message) (text "module") (object))

        (object $assign<ext.ext>ext
            (self) (global.get $imports)
        )
    )
)