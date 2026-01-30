(module

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