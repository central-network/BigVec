
    (func $assign
        (param $label   <String>)
        (param $value  externref)

        (reflect $set<ext.ext.ext> 
            (self) 
            (local.get $label) 
            (local.get $value)
        )
    )

    (func $remove
        (param $label   <String>)

        (reflect $deleteProperty<ext.ext> 
            (self) 
            (local.get $label)
        )
    )

    (func $at
        (param $array <Array>)
        (param $index     i32)
        (result     externref)

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $Array:at)
            (this)
            (array $of<i32>ext (local.get $index))
        )
    )

    (func $exports
        (param $instance <Instance>)
        (result            <Object>)

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $WebAssembly.Instance:exports[get])
            (this)
            (array)
        )
    )

    (func $compile
        (param $source externref)
        (result <Promise>)
        
        (reflect $apply<ext.ext.ext>ext
            (ref.extern $WebAssembly.compile)
            (ref.extern $WebAssembly)
            (array $of<ext>ext (local.get $source))
        )
    )

    (func $instantiate
        (param $module externref)
        (result <Promise>)
        
        (reflect $apply<ext.ext.ext>ext
            (ref.extern $WebAssembly.instantiate)
            (ref.extern $WebAssembly)
            (array $of<ext.ext>ext (local.get $module) (self))
        )
    )