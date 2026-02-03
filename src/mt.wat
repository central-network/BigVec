(module $mt
    (include "shared/memory.wat")
    (include "shared/imports.wat")
    (include "shared/worker.wat")

    (data $worker.js "file://worker.js")
    (data $mt_self "wasm://mt_self.wat")
    (data $mt_agent "wasm://mt_agent.wat")
    (data $mt_console "wasm://bind_console/mt.wat")
    (data $console "file://../wasm/console.wasm")

    (global $module.console mut i32)
    (global $module.mt_self mut i32)
    (global $module.mt_agent mut i32)
    (global $module.mt_console mut i32)

    (global $MODULE_OFFSET mut i32)
    (global $MODULE_LENGTH i32 i32(64))

    (main $portal
        (apply $Performance:now<ext>f32
            (self $performance<ext>)
        )

        (apply $Promise:then
            (param externref externref)
            (result externref)
            (self)
            (array $of<fun>ext 
                (apply $navigator.gpu<ext>ext
                    (self $navigator)
                )
            )
        )

        (apply $Promise:catch
            (param externref externref)
            (result externref)
            (self)
            (array $of<fun>ext 
                (apply $navigator.gpu<ext>ext
                    (self $navigator)
                )
            )
        )

        (apply $WebAssembly.Memory:buffer[get]
            (param)
            (result externref)
            (self)
            (array)
        )

        (set.extern (self) (text "wasm") (wasm))
        (async
            (array $fromAsync<ext>ext
                (array $of<ext.ext.ext.ext>ext
                    (wasm.compile (data.view $console))
                    (wasm.compile (data.view $mt_self))
                    (wasm.compile (data.view $mt_agent))
                    (wasm.compile (data.view $mt_console))
                )
            )
            (then $oncompile
                (param $items    <Array>)
                (result        <Promise>)
                (local $module  <Module>)

                (local.tee $module (get.i32_extern (this) i32(1)))
                (global.set $module.mt_self (table.add $externref (true)))
                (wasm.set_i32 "module.mt_self" (global.get $module.mt_self))

                (local.tee $module (get.i32_extern (this) i32(2)))
                (global.set $module.mt_agent (table.add $externref (true)))
                (wasm.set_i32 "module.mt_agent" (global.get $module.mt_agent))

                (local.tee $module (get.i32_extern (this) i32(3)))
                (global.set $module.mt_console (table.add $externref (true)))
                (wasm.set_i32 "module.mt_console" (global.get $module.mt_console))

                (local.tee $module (get.i32_extern (this) i32(0)))
                (global.set $module.console (table.add $externref (true)))
                (wasm.set_i32 "module.console" (global.get $module.console))

                (wasm.instantiate (local.get $module))
            ) 
            (then $onconsolemodule
                (call $main)
            )
        )
    )

    (func $main
        (local $module  <Module>)
        (global.set $MODULE_OFFSET (malloc (global.get $MODULE_LENGTH)))

        (wasm.export (ref.module $mt) (ref.func $fork))
        (wasm.export (ref.module $mt) (ref.func $ref))
        (wasm.export (ref.module $mt) (ref.func $close))

        (local.set $module (table.get $externref (global.get $module.mt_console)))
        (wasm.instantiate (local.get $module))
        (drop)
    )

    (func $fork
        (param $count           i32)
        (result                 i32)
        (local $instance <Instance>)
        (local $index           i32)

        (async
            (wasm.instantiate $module.mt_self)
            (then $oninstance
                (param $instance <Instance>)
                (warn (this))
            )
        )
        (true)
    )

    (func $close
        (param $index        i32)
    )

    (func $ref
        (param $index        i32)
        (result         <Worker>)

        (null)
    )

)