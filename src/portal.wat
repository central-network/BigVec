(module
    (table $module 1 65536 externref)
    (table $process 1 65536 externref)
    (table $hanlders 1 65536 externref)

    (data $idb "file://../wasm/idb.wasm")

    (export "instantiate" (func $instantiate))
    (export "compile" (func $compile))
    (export "fetch" (func $fetch))
    (export "install" (func $install))
    (export "start" (func $start))
    (export "module" (table $module))
    (export "process" (table $process))
    (export "memory" (global $memory))
    (export "boot" (func $boot))
    (export "idb" (global $idb))

    (global $idb mut ext)
    (global $memory mut ext)

    (global $PAGESIZE_INITIAL i32 i32(1))
    (global $PAGESIZE_MAXIMUM i32 i32(65536))
    (global $MEMORY_IS_SHARED i32 (true))

    (func $boot 
        (result                 <Promise>)
        (local $descriptor       <Object>)
        (local $memory           <Memory>)
        (local $buffer      <ArrayBuffer>)
        (local $dataView       <DataView>)
        (local $uInt8Array   <Uint8Array>)
        (local $int32Array   <Int32Array>)

        (local.set $descriptor
            (object $fromEntries<ext>ext
                (array $of<ext.ext.ext>ext
                    (array $of<ext.i32>ext (text "initial") (global.get $PAGESIZE_INITIAL))
                    (array $of<ext.i32>ext (text "maximum") (global.get $PAGESIZE_MAXIMUM))
                    (array $of<ext.i32>ext (text "shared")  (global.get $MEMORY_IS_SHARED))
                )
            )
        )

        (local.set $memory
            (reflect $construct<ext.ext>ext 
                (ref.extern $WebAssembly.Memory) 
                (array $of<ext>ext (local.get $descriptor))
            )
        )
        
        (local.set $buffer
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $WebAssembly.Memory:buffer[get])
                (local.get $memory)
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

        (object $assign<ext.ext> 
            (local.get $memory)
            (object $fromEntries<ext>ext
                (array $of<ext.ext.ext.ext.ext.ext.ext>ext
                    (array $of<ext.ext>ext (text "dataview") (local.get $dataView))
                    (array $of<ext.ext>ext (text "uint8array") (local.get $uInt8Array))
                    (array $of<ext.ext>ext (text "int32array") (local.get $int32Array))
                    (array $of<ext.i32>ext (text "pagesize_initial") (global.get $PAGESIZE_INITIAL))
                    (array $of<ext.i32>ext (text "pagesize_maximum") (global.get $PAGESIZE_MAXIMUM))
                    (array $of<ext.i32>ext (text "buffer_length_initial") (i32.mul (global.get $PAGESIZE_INITIAL) i32(65536)))
                    (array $of<ext.i32>ext (text "buffer_length_maximum") (i32.mul (global.get $PAGESIZE_MAXIMUM) i32(65536)))
                )
            )        
        )

        (global.set $memory 
            (local.get $memory)
        )

        (reflect $set<ext.ext.ext> 
            (self) 
            (text "memory") 
            (local.get $memory)
        )

        (async.ext
            (call $instantiate (data.view $idb))
            (then $oninstanced
                (param $instantiate <Object>)
                (result            <Promise>)

                (global.set $idb 
                    (call $exports (this))
                )
                
                (reflect $apply<ext.ext.ext>ext 
                    (reflect $get<ext.ext>ext 
                        (global.get $idb) 
                        (text "open")
                    )
                    (null)
                    (array $of<ext.ext>ext 
                        (text "portal") 
                        (text "module")
                    )
                )
            )
            (then $onidbopen
                (result <Promise>)

                (reflect $apply<ext.ext.ext>ext 
                    (reflect $get<ext.ext>ext 
                        (global.get $idb) 
                        (text "count")
                    )
                    (null)
                    (array)
                )
            )
            (then $onidbcount
                (param $count            i32)
                (console $log<i32> (this))
                (table.grow $module (null) (this))
                (drop)
            )
        )
    )

    (func $start
        (param $app                             i32)
        (result                                 i32)
        (local $pid                             i32)

        (local.set $pid 
            (table.grow $process 
                (call $resolve 
                    (table.get $module 
                        (local.get $app)
                    )
                )
                (true)
            )
        )

        (async 
            (array $fromAsync<ext>ext
                (array $of<ext.i32>ext
                    (table.get $process (local.get $pid))
                    (local.get $pid)
                )
            )
            (then $onmodule
                (param $items              <Array>)
                (result                  <Promise>)
                (local $module            <Module>)
                (local $instantination   <Promise>)
                (local $index                  i32)

                (local.set $module (reflect $get<ext.i32>ext (this) i32(0)))
                (local.set $index (reflect $get<ext.i32>i32 (this) i32(1)))

                (table.set $process 
                    (local.get $index)
                    (call $instantiate (local.get $module))
                )

                (reflect $set<ext.i32.ext> 
                    (local.get $items) 
                    (i32.const 0) 
                    (table.get $process (local.get $index))
                )

                (array $fromAsync<ext>ext (this))
            )
            (then $oninstantiate
                (param $items             <Array>)
                (local $instance       <Instance>)
                (local $index                 i32)

                (local.set $instance (reflect $get<ext.i32>ext (this) i32(0)))
                (local.set $index (reflect $get<ext.i32>i32 (this) i32(1)))
                
                (table.set $process 
                    (local.get $index) 
                    (local.get $instance)
                )
            )
        )

        (local.get $pid)
    )

    (func $exports
        (param $result           <Instance|Object>)
        (result                           <Object>)

        (if (reflect $has<ext.ext>i32 (this) (text "instance"))
            (then (local.set 0 (reflect $get<ext.ext>ext (this) (text "instance"))))
        )

        (if (reflect $has<ext.ext>i32 (this) (text "exports"))
            (then (return (reflect $get<ext.ext>ext (this) (text "exports"))))
        )

        (object)
    )

    (func $install
        (param $url                       <String>)
        (result                                i32)
        (local $index                          i32)
        (local $fetch                    <Request>)

        (local.set $fetch
            (call $fetch (local.get $url))
        )
        
        (local.set $index 
            (table.grow $module
                (local.get $fetch) 
                (true)
            )
        )

        (async 
            (array $fromAsync<ext>ext
                (array $of<i32.ext>ext
                    (local.get $index)
                    (local.get $fetch)
                )
            )
            (then $onbuffer
                (param $items              <Array>)
                (result                  <Promise>)

                (reflect $set<ext.i32.ext> 
                    (this)
                    (i32.const 2)
                    (reflect $apply<ext.ext.ext>ext 
                        (reflect $get<ext.ext>ext (global.get $idb) (text "set"))
                        (null)
                        (local.get $items)
                    )
                )

                (array $fromAsync<ext>ext (this))
            )
            (then $onpersist
                (param $items              <Array>)
                (result                  <Promise>)

                (reflect $set<ext.i32.ext> 
                    (this)
                    (i32.const 1)
                    (call $compile (reflect $get<ext.i32>ext (this) i32(1)))
                )

                (array $fromAsync<ext>ext (this))
            )
            (then $onmodule
                (param $items             <Array>)
                (local $module           <Module>)
                (local $index                 i32)

                (local.set $index (reflect $get<ext.i32>i32 (this) i32(0)))
                (local.set $module (reflect $get<ext.i32>ext (this) i32(1)))

                (table.set $module 
                    (local.get $index) 
                    (local.get $module)
                )
            )
        )

        (local.get $index)
    )

    (func $resolve
        (param $any                       <Object>)
        (result                          <Promise>)

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $Promise.resolve)
            (ref.extern $Promise)
            (array $of<ext>ext (this))
        )
    )   

    (func $compile
        (param $source                    <Buffer>)
        (result                          <Promise>)

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $WebAssembly.compile)
            (ref.extern $WebAssembly)
            (array $of<ext>ext (this))
        )
    )   

    (func $instantiate
        (param $module                    <Module>)
        (result                          <Promise>)

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $WebAssembly.instantiate)
            (ref.extern $WebAssembly)
            (array $of<ext.ext>ext (this) (self))
        )
    )   

    (func $fetch
        (param $target                    <String>)
        (result                          <Promise>)

        (async.ext
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $fetch)
                (self)
                (array $of<ext>ext (this))
            )
            (then $onresponse
                (param $response        <Response>)
                (result              <ArrayBuffer>)

                (reflect $apply<ext.ext.ext>ext
                    (ref.extern $Response:arrayBuffer)
                    (this)
                    (array)
                )
            )
        )
    )
)