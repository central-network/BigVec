(module
    (import "self" "global" (table $global 1 65536 externref))

    (include "shared/global.wat")

    (main $set_globals
        (;
            set global to table.global index
            get from table with this index
            and set global from external value

            something like that... 💞
        ;)
    )
)