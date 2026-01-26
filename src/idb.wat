(module
    (export "open"          (func $open))
    (export "del"            (func $del))
    (export "get"            (func $get))
    (export "set"            (func $set))
    (export "has"            (func $has))
    (export "count"        (func $count))
    (export "version"    (func $version))

    (global $idbase           mut ext)
    (global $onopen           mut ext)
    (global $config           mut ext)
    (global $version          mut i32)
    (global $database         mut ext)
    (global $storename        mut ext)

    (func $get_delayer
        (result              <Promise>)
        (local $withResolvers <Object>)
        
        (if (ref.is_null (global.get $idbase))
            (then
                (local.set $withResolvers
                    (reflect $apply<ext.ext.ext>ext
                        (ref.extern $Promise.withResolvers)
                        (ref.extern $Promise)
                        (array)
                    )
                )

                (global.set $idbase (reflect $get<ext.ext>ext (local.get $withResolvers) (text "promise")))
                (global.set $onopen (reflect $get<ext.ext>ext (local.get $withResolvers) (text "resolve")))
            )
        )

        (global.get $idbase)
    )

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

        (call $get_delayer)

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

                (reflect $apply<ext.ext.ext> 
                    (global.get $onopen) 
                    (global.get $idbase) 
                    (array $of<ext>ext 
                        (global.get $database)
                    )
                )
            )
        )
    )

    (func $get_writer
        (param $key      <String|Number>)
        (param $value          externref)
        (result                <Promise>)
        
        (array $fromAsync<ext>ext
            (array $of<ext.ext.ext.ext>ext 
                (call $get_delayer)
                (call $IDBTransaction:objectStore 
                    (call $IDBDatabase:transaction 
                        (global.get $database) 
                        (global.get $storename) 
                        (text "readwrite")
                    )
                    (global.get $storename)
                )
                (local.get $key) 
                (local.get $value) 
            )
        )
    )

    (func $get_reader
        (param $key      <String|Number>)
        (result                <Promise>)

        (array $fromAsync<ext>ext 
            (array $of<ext.ext.ext>ext 
                (call $get_delayer)
                (call $IDBTransaction:objectStore 
                    (call $IDBDatabase:transaction 
                        (global.get $database) 
                        (global.get $storename) 
                        (text "readonly")
                    )
                    (global.get $storename)
                )
                (local.get $key) 
            )
        )
    )

    (func $get
        (param $key                 <String>)
        (result                    <Promise>)

        (async.ext 
            (call $get_reader (this))
            (then $onidbreader 
                (param $items          <Array>)
                (result              <Promise>)

                (call $IDBObjectStore:get 
                    (reflect $get<ext.i32>ext (this) i32(1))
                    (reflect $get<ext.i32>ext (this) i32(2))
                )
            )
        )
    )
    
    (func $has
        (param $key          <String|Number>)
        (result                    <Promise>)

        (async.ext 
            (call $get_reader (this))
            (then $onidbreader 
                (param $items          <Array>)
                (result              <Promise>)

                (call $IDBObjectStore:getKey 
                    (reflect $get<ext.i32>ext (this) i32(1))
                    (reflect $get<ext.i32>ext (this) i32(2))
                )
            )
        )
    )

    (func $set
        (param $key       <String|Number>)
        (param $value           externref)
        (result                 <Promise>)

        (async.ext 
            (call $get_writer (this) (local.get $value))
            (then $onidbwriter 
                (param $items               <Array>)
                (result                   <Promise>)

                (call $IDBObjectStore:put 
                    (reflect $get<ext.i32>ext (this) i32(1))
                    (reflect $get<ext.i32>ext (this) i32(3))
                    (reflect $get<ext.i32>ext (this) i32(2))
                )
            )
        )
    )

    (func $count
        (result <Promise>)

        (async.ext 
            (call $get_reader (null))
            (then $onreader
                (param $items          <Array>)
                (result              <Promise>)

                (call $IDBObjectStore:count
                    (reflect $get<ext.i32>ext (this) i32(1))
                )
            )
        )
    )

    (func $del
        (param $key          <String|Number>)
        (result                    <Promise>)

        (async.ext 
            (call $get_writer (this) (null))
            (then $onidbwriter 
                (param $items          <Array>)
                (result              <Promise>)

                (call $IDBObjectStore:delete 
                    (reflect $get<ext.i32>ext (this) i32(1))
                    (reflect $get<ext.i32>ext (this) i32(2))
                )
            )
        )
    )

    (func $version
        (result i32)
        (global.get $version)
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
    )

    (func $IDBObjectStore:remove
        (param $store       <IDBObjectStore>)
        (param $index                    i32)
        (result                    <Promise>)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:delete)
                (this)
                (array $of<i32>ext (local.get $index))
            )
        )
    )

    (func $IDBObjectStore:count
        (param $store       <IDBObjectStore>)
        (result                    <Promise>)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:count)
                (this)
                (array)
            )
        )
    )

    (func $IDBObjectStore:delete
        (param $store       <IDBObjectStore>)
        (param $key                 <String>)
        (result                    <Promise>)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:delete)
                (this)
                (array $of<ext>ext (local.get $key))
            )
        )
    )

    (func $IDBObjectStore:get
        (param $store       <IDBObjectStore>)
        (param $key                 <String>)
        (result                    <Promise>)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:get)
                (this)
                (array $of<ext>ext 
                    (local.get $key)
                )
            )
        )
    )

    (func $IDBObjectStore:at
        (param $store       <IDBObjectStore>)
        (param $index                    i32)
        (result                    <Promise>)

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

    (func $IDBObjectStore:getIndex
        (param $store       <IDBObjectStore>)
        (param $index                    i32)
        (result                    <Promise>)

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
                    (reflect $get<ext.i32>i32 (this) i32(0))
                    (reflect $get<ext.i32>i32 (this) i32(1))
                )
            )
        )
    )

    (func $IDBObjectStore:getKey
        (param $store       <IDBObjectStore>)
        (param $key                 <String>)
        (result                    <Promise>)

        (async.ext
            (array $fromAsync<ext>ext
                (array $of<ext.ext>ext
                    (local.get $key) 
                    (call $async_request
                        (reflect $apply<ext.ext.ext>ext
                            (ref.extern $IDBObjectStore:getKey)
                            (this)
                            (array $of<ext>ext (local.get $key))
                        )
                    )
                )
            )
            (then $ongetkeydone
                (param $async <Array>)
                (result i32)
                (object $is<ext.ext>i32 
                    (reflect $get<ext.i32>ext (this) i32(0))
                    (reflect $get<ext.i32>ext (this) i32(1))
                )
            )
        )
    )

    (func $IDBObjectStore:set
        (param $store       <IDBObjectStore>)
        (param $value              externref)
        (param $index                    i32)
        (result                    <Promise>)

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

    (func $IDBObjectStore:put
        (param $store       <IDBObjectStore>)
        (param $value              externref)
        (param $key                 <String>)
        (result                    <Promise>)

        (call $async_request
            (reflect $apply<ext.ext.ext>ext
                (ref.extern $IDBObjectStore:put)
                (this)
                (array $of<ext.ext>ext 
                    (local.get $value) 
                    (local.get $key)
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
        (param $request         <IDBRequest>)
        (result                    <Promise>)    

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $IDBRequest:result[get])
            (this)
            (array)
        )
    )
    
    (func $Event:target
        (param $event                <Event>)
        (result                    externref)    

        (reflect $apply<ext.ext.ext>ext
            (ref.extern $Event:target[get])
            (this)
            (array)
        )
    )

    (func $async_request
        (param $request         <IDBRequest>)
        (result                    <Promise>)
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