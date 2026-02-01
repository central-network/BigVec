(module
    (include "shared/imports.wat")

    (include "call_indirect/idb.wat")
    (include "call_indirect/console.wat")

    (main $register_command
        (call $console.register_command
            (text "idb")
            (ref.func $handle_command)
            (array $of<ext.ext.ext.ext.ext.ext.ext>ext 
                (text "help") 
                (text "open") 
                (text "get") 
                (text "set") 
                (text "del")    
                (text "has")
                (text "count")
            )
        )
    )

    (func $print_async_command_result 
        (param $call <Promise>)
        (result      <Promise>)
        
        (reflect $apply<ext.ext.ext>
            (ref.extern $Promise:then)
            (local.get $call)
            (array $of<ext>ext (ref.extern $console.warn))
        )

        (this)
    )

    (func $handle_command
        (param $arguments <Array>)
        (result         <Promise>)

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-open"))
            (then 
                (call $idb.open
                    (get.i32_extern (this) i32(1))
                    (get.i32_extern (this) i32(2))
                    (get.i32 (this) i32(3))
                )
                (return (call $print_async_command_result))
            )
        )

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-get"))
            (then 
                (call $idb.get (get.i32_extern (this) i32(1)))
                (return (call $print_async_command_result))
            )
        )

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-set"))
            (then 
                (call $idb.set 
                    (get.i32_extern (this) i32(1))
                    (get.i32_extern (this) i32(2))
                )
                (return (call $print_async_command_result))
            )
        )

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-has"))
            (then 
                (call $idb.has (get.i32_extern (this) i32(2)))
                (return (call $print_async_command_result))
            )
        )

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-del"))
            (then 
                (call $idb.del (get.i32_extern (this) i32(2)))
                (return (call $print_async_command_result))
            )
        )

        (if (object $is<ext.ext>i32 (get.i32_extern (this) i32(0)) (text "-count"))
            (then 
                (call $idb.count)
                (return (call $print_async_command_result))
            )
        )
        
        (console $table<ext>
            (array $of<ext.ext.ext.ext.ext.ext.ext>ext
                (array $of<ext.ext.ext.ext>ext (text "open") (text "idb -open [DBNAME] [STORENAME] [?VERSION]") (text "open indexed database with fixed object store") (text "idb -open `mydb` `myobjectstore` [2]"))   
                (array $of<ext.ext.ext.ext>ext (text "get") (text "idb -get [KEY]") (text "get requested key value from open database and object store") (text "idb -get `keyname`"))   
                (array $of<ext.ext.ext.ext>ext (text "set") (text "idb -set [KEY] [VALUE]") (text "put given object in open store with key") (text "idb -set `keyname` `keyvalue`"))   
                (array $of<ext.ext.ext.ext>ext (text "del") (text "idb -del [KEY]") (text "remove given key and stored object from open database") (text "idb -del `keyname`"))      
                (array $of<ext.ext.ext.ext>ext (text "has") (text "idb -has [KEY]") (text "checks is object store contains given key") (text "idb -has `keyname`"))  
                (array $of<ext.ext.ext.ext>ext (text "count") (text "idb -count") (text "return key count of open database and selected object store") (text "idb -count"))                              
                (array $of<ext.ext.ext.ext>ext (text "help") (text "idb -help") (text "show this message") (text "idb -help"))  
            )
        )

        (null)
    )
)