(module 
    (func $01-basic
        (global.get $self.location.origin<ext>)
        (drop)
    )

    (func $03-extern-of-number
        (global.get $self.performance.eventCounts.size<ext>)
        (drop)
    )

    (func $04-number-of-number
        (global.get $self.performance.interactionCount<i32>)
        (drop)
    )

    (func $05-accessor-of-object
        (global.get $self.Performance.prototype.interactionCount[get])
        (drop)
    )

    (func $06-prototype-keyword-from-<:>-symbol
        (global.get $self.Performance:timeOrigin[get])
        (drop)
    )
)