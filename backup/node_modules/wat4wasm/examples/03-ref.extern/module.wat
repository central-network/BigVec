(module 
    (func $main
        (ref.extern $self.navigation.activation.entry.id)
        (drop)

        (ref.extern $self.location)
        (drop)

        (ref.extern $self.location.origin)
        (drop)

        (ref.extern $self.Worker.prototype.postMessage)
        (drop)

        (ref.extern $self.Worker:postMessage)
        (drop)

        (ref.extern $self.Worker:onmessage[get])
        (drop)

        (ref.extern $self.Worker.prototype.onmessage[set])
        (drop)

        (ref.extern $self.MessageEvent.prototype.data[get])
        (drop)

        (ref.extern $self.MessageEvent:data[get])
        (drop)

        (ref.extern $self.MessageEvent:initMessageEvent)
        (drop)
    )
)