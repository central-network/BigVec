(module
    (export "open"       (func $open))
    (export "get"         (func $get))
    (export "set"         (func $set))
    (export "count"     (func $count))
    (export "remove"   (func $remove))
    (export "add"         (func $add))
    (export "has"         (func $has))
    (export "version" (func $version))

    (global $version          mut i32)
    (global $database         mut ext)
    (global $storename        mut ext)

    (func $open
        (param $dbname       <String>)
        (param $storename    <String>)
        (param $version           i32)
        (result             <Promise>)

        (global.set $storename  
            (if (result externref) 
                (ref.is_null (local.get $storename))
                (then (local.get $dbname))
                (else (local.get $storename))
            )
        )

        (global.set $version
            (select 
                (local.get $version) 
                (true) 
                (local.get $version)
            )
        )

        (async.ext
            (call $IDBFactory:open 
                (local.get $dbname)
                (global.get $version)
                (func $onneedupgrade
                    (param $event <IDBVersionChangeEvent>)

                    (global.set $database 
                        (call $IDBRequest:result
                            (call $Event:target (this))
                        )
                    )
                    
                    (call $IDBDatabase:createObjectStore 
                        (global.get $database) 
                        (global.get $storename) 
                    )
                ) 
                (func $onopensucceed
                    (param $event <IDBOpenDBSuccessEvent>)

                    (global.set $database 
                        (call $IDBRequest:result
                            (call $Event:target (this))
                        )
                    )
                )
            )
        )
    )

    (func $get
        (param $index                    i32)
        (result                    <Promise>)

        (call $IDBObjectStore:get
            (call $new_reader)
            (local.get $index)
        )
    )

    (func $has
        (param $index                    i32)
        (result                    <Promise>)

        (call $IDBObjectStore:getKey
            (call $new_reader)
            (local.get $index)
        )
    )

    (func $set
        (param $index                    i32)
        (param $value              externref)
        (result                    <Promise>)

        (call $IDBObjectStore:put
            (call $new_writer)
            (local.get $value)
            (local.get $index)
        )
    )

    (func $count
        (result <Promise>)
        (call $IDBObjectStore:count (call $new_reader))
    )

    (func $version
        (result i32)
        (global.get $version)
    )

    (func $add
        (param $value              externref)
        (result                    <Promise>)

        (async.ext 
            (array $fromAsync<ext>ext
                (array $of<ext.ext>ext
                    (call $count) (local.get $value)
                )
            )
            (then $oncountdone
                (param $arguments   <Array>)
                (result           <Promise>)
                (local $index           i32)
                (local $value     externref)

                (local.set $index (reflect $get<ext.i32>i32 (this) (i32.const 0)))
                (local.set $value (reflect $get<ext.i32>ext (this) (i32.const 1)))

                (array $fromAsync<ext>ext
                    (array $of<i32.ext>ext
                        (local.get $index)
                        (call $set (local.get $index) (local.get $value))
                    )
                )
            )
            (then $onsetcomplete
                (param $async <Array>)
                (result i32)
                (reflect $get<ext.i32>i32 (this) (i32.const 0))
            )
        )
    )

    (func $remove
        (param $index                    i32)
        (result                    <Promise>)

        (call $IDBObjectStore:delete
            (call $new_writer)
            (local.get $index)
        )
    )

    (func $new_reader
        (result <ObjectStore>)

        (call $IDBTransaction:objectStore 
            (call $IDBDatabase:transaction 
                (global.get $database) 
                (global.get $storename) 
                (text "readonly")
            )
            (global.get $storename)
        )
    )

    (func $new_writer
        (result <ObjectStore>)

        (call $IDBTransaction:objectStore 
            (call $IDBDatabase:transaction 
                (global.get $database) 
                (global.get $storename) 
                (text "readwrite")
            )
            (global.get $storename)
        )
    )

    (func $IDBObjectStore:count
        (param $store       <IDBObjectStore>)
        (result                    externref)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:count)
                (this)
                (array)
            )
        )
    )

    (func $IDBObjectStore:keys
        (param $store       <IDBObjectStore>)
        (result                    externref)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:getAllKeys)
                (this)
                (array)
            )
        )
    )

    (func $IDBDatabase:transaction
        (param $idb            <IDBDatabase>)
        (param $name                <String>)
        (param $mode                <String>)
        (result             <IDBTransaction>)
        
        (reflect $apply<ext.ext.ext>ext
            (ref.extern $IDBDatabase:transaction)
            (this)
            (array $of<ext.ext>ext
                (local.get $name)
                (local.get $mode)
            )
        )
    )

    (func $IDBTransaction:objectStore
        (param $transaction <IDBTransaction>)
        (param $name                <String>)
        (result             <IDBObjectStore>)
        
        (reflect $apply<ext.ext.ext>ext
            (ref.extern $IDBTransaction:objectStore)
            (this)
            (array $of<ext>ext (local.get $name))
        )
    )

    (func $IDBFactory:open
        (param $name                <String>)
        (param $version                  i32)
        (param $upgradehandler       funcref)
        (param $successhandler       funcref)
        (result                    <Promise>)
        (local $openreq   <IDBOpenDBRequest>)

        (local.set $openreq
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBFactory:open)
                (ref.extern $indexedDB)
                (array $of<ext.i32>ext 
                    (local.get $name)
                    (local.get $version)
                )
            )
        )

        (if (i32.eqz (ref.is_null (local.get $upgradehandler)))
            (then
                (reflect $apply<ext.ext.ext>
                    (ref.extern $EventTarget:addEventListener)
                    (local.get $openreq)
                    (array $of<ext.fun>ext 
                        (text "upgradeneeded") 
                        (local.get $upgradehandler)
                    )
                )
            )
        )

        (if (i32.eqz (ref.is_null (local.get $successhandler)))
            (then
                (reflect $apply<ext.ext.ext>
                    (ref.extern $EventTarget:addEventListener)
                    (local.get $openreq)
                    (array $of<ext.fun>ext 
                        (text "success") 
                        (local.get $successhandler)
                    )
                )
            )
        )
        
        (call $async_request (local.get $openreq))
    )

    (func $IDBObjectStore:delete
        (param $store       <IDBObjectStore>)
        (param $index                    i32)
        (result                    externref)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:delete)
                (this)
                (array $of<i32>ext (local.get $index))
            )
        )
    )

    (func $IDBObjectStore:get
        (param $store       <IDBObjectStore>)
        (param $index                    i32)
        (result                    externref)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:get)
                (this)
                (array $of<i32>ext 
                    (local.get $index)
                )
            )
        )
    )

    (func $IDBObjectStore:getKey
        (param $store       <IDBObjectStore>)
        (param $index                    i32)
        (result                    externref)

        (async.ext
            (array $fromAsync<ext>ext
                (array $of<i32.ext>ext
                    (local.get $index) 
                    (call $async_request
                        (reflect $apply<ext.ext.ext>ext
                            (ref.extern $IDBObjectStore:getKey)
                            (this)
                            (array $of<i32>ext (local.get $index))
                        )
                    )
                )
            )
            (then $ongetkeydone
                (param $async <Array>)
                (result i32)
                (i32.eq 
                    (reflect $get<ext.i32>i32 (this) (i32.const 0))
                    (reflect $get<ext.i32>i32 (this) (i32.const 1))
                )
            )
        )
    )

    (func $IDBObjectStore:put
        (param $store       <IDBObjectStore>)
        (param $value              externref)
        (param $index                    i32)
        (result                    externref)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:put)
                (this)
                (array $of<ext.i32>ext 
                    (local.get $value) 
                    (local.get $index)
                )
            )
        )
    )

    (func $IDBDatabase:createObjectStore
        (param $database       <IDBDatabase>)
        (param $name                <String>)

        (reflect $apply<ext.ext.ext>
            (ref.extern $IDBDatabase:createObjectStore)
            (local.get $database)
            (array $of<ext>ext (local.get $name))
        )
    )

    (func $IDBRequest:result
        (param $request            externref)
        (result                    externref)    

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $IDBRequest:result[get])
            (this)
            (array)
        )
    )
    
    (func $Event:target
        (param $event              externref)
        (result                    externref)    

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $Event:target[get])
            (this)
            (array)
        )
    )

    (func $async_request
        (param $request            externref)
        (result                    externref)
        (local $withResolvers       <Object>)

        (local.set $withResolvers 
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $Promise.withResolvers)
                (ref.extern $Promise)
                (array)
            )
        )

        (reflect $apply<ext.ext.ext>
            (ref.extern $IDBRequest:onsuccess[set])
            (local.get $request)
            (array $of<ext>ext 
                (reflect $get<ext.ext>ext 
                    (local.get $withResolvers) 
                    (text "resolve")
                )
            )
        )

        (reflect $apply<ext.ext.ext>
            (ref.extern $IDBRequest:onerror[set])
            (local.get $request)
            (array $of<ext>ext 
                (reflect $get<ext.ext>ext 
                    (local.get $withResolvers) 
                    (text "reject")
                )
            )
        )

        (async.ext
            (reflect $get<ext.ext>ext 
                (local.get $withResolvers) 
                (text "promise")
            )
            (then $onopensuccess 
                (param $event              <Event>)
                (result         <IDBOpenDBRequest>)
                (call $Event:target (this))
            )
            (then $oneventtarget
                (param $request       <IDBRequest>)
                (result              <IDBDatabase>)
                (call $IDBRequest:result (this))
            )
        )
    )
)