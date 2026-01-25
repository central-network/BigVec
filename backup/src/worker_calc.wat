(module
    (include "include/imports.wat")
    (import "uuid" "memory" (global $memory externref))
    
    (global $memorView mut ext)

    (main $worker_thread_calc
        (console $warn<ext> (global.get $memory))            
        
        (global.set $memorView
            (call $create_viewer
                (call $memory_buffer
                    (global.get $memory)
                )
            )
        )

        (console $warn<ext> (global.get $memorView))            
    )

    (func $import_packet
        (param $index                                i32)
        (result                                <Promise>)

        (async.ext
            (call $idb.get (local.get $index))
            (then $onpacketbuffer
                (param $packetBuffer       <ArrayBuffer>)

                (call $set_arrayview 
                    (global.get $memorView) 
                    (call $create_viewer 
                        (local.get $packetBuffer)
                    )
                )
            )
        )
    )

    (func $create_viewer
        (param $buffer   <ArrayBuffer|SharedArrayBuffer>)
        (result                             <Uint8Array>)
        
        (reflect $construct<ext.ext>ext
            (ref.extern $Uint8Array)
            (array $of<ext>ext (local.get $buffer))
        )
    )

    (func $memory_buffer
        (param $memory              <WebAssembly.Memory>)
        (result          <ArrayBuffer|SharedArrayBuffer>)
        
        (reflect $apply<ext.ext.ext>ext
            (ref.extern $WebAssembly.Memory:buffer[get])
            (local.get $memory)
            (array)
        )
    )

    (func $set_arrayview
        (param $target                      <TypedArray>)
        (param $source                      <TypedArray>)
        
        (reflect $apply<ext.ext.ext>
            (ref.extern $TypedArray:set)
            (local.get $target)
            (array $of<ext>ext (local.get $source))
        )
    )
)