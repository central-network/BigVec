const commands = {};
const definers = {};
const cleaners = {};
const handlers = {};

const global_param_values = [];

const bounded_param_reset = Reflect.apply(
    Function.prototype.bind,
    Reflect.set,
    Array.of(null, global_param_values, "length", 0)
);

const bounded_window_delete = Reflect.apply(
    Function.prototype.bind,
    Reflect.deleteProperty,
    Array.of(null, self)
);

const isSymbol = Reflect.apply(
    Function.prototype.bind,
    Object.is,
    Array.of(
        Object, 
        Symbol.toPrimitive
    )
);

const isNumber = (value) => !Reflect.apply(
    isNaN, null, Array.of(value)
);

const proxy = new Proxy(function (){}, {
    apply: function(target, thisArg, args) {
		Reflect.apply(
            Array.prototype.push, 
            global_param_values, 
            Reflect.apply(
                Array.prototype.flat,
                args,
                Array()
            )
        );

        return proxy;
    },

    get: function(target, prop) {
        if (Reflect.apply(isSymbol, null, Array.of(prop))) {
            return Number;
        }

        if (Reflect.apply(isNumber, null, Array.of(prop))) {
            prop = Reflect.apply(Number, null, Array.of(prop));
        }
		
        Reflect.apply(
            Array.prototype.push, 
            global_param_values, 
            Array.of(prop)
        );

        return proxy;
    }
});

const parameter_trap = function (name) { 

    Reflect.apply(
        Array.prototype.push, 
        global_param_values, 
        Array.of(
            Reflect.apply(
                String.prototype.concat,
                String("-"),
                Array.of(name)
            )
        )
    );

	return proxy; 
};

const handle_request = function (name) {

    Reflect.apply(bounded_param_reset, null, Array());

    Reflect.apply(Reflect.get(definers, name), null, Array());
	Reflect.apply(Reflect.get(handlers, name), null, Array());
	Reflect.apply(Reflect.get(cleaners, name), null, Array());
			
    return proxy;
};

function createGetterDescriptor (handler) {
    const descriptor = Object();

    Reflect.set(descriptor, String("configurable"), 1);
	Reflect.set(descriptor, String("get"), handler);

    return descriptor;
}

function defineShellCommand(command, handler) {
    
	const command_bounded_getter = Reflect.apply(
        Function.prototype.bind,
        handle_request,
        Array.of(null, command)
    );

    const queue_bounded_dispatch = Reflect.apply(
        Function.prototype.bind,
        handler,
        Array.of(null, global_param_values)
    );
    
    const delayed_command_handle = Reflect.apply(
        Function.prototype.bind,
        setTimeout,
        Array.of(null, queue_bounded_dispatch)
    );

    Reflect.defineProperty(
        self, 
        command, 
        createGetterDescriptor(command_bounded_getter)
    );

    Reflect.set(commands, command, Object());
    Reflect.set(definers, command, Function());
    Reflect.set(cleaners, command, Function());
    Reflect.set(handlers, command, delayed_command_handle);
};

function defineCommandParameter(command, parameter) {

	const command_descriptors = Reflect.get(
        commands, 
        command
    );

	const argument_bounded_getter = Reflect.apply(
        Function.prototype.bind,
        parameter_trap,
        Array.of(null, parameter)
    );

    Reflect.set(
        command_descriptors, 
        parameter, 
        createGetterDescriptor(argument_bounded_getter) 
    );

    const command_all_parameters = Reflect.ownKeys(
        command_descriptors
    );
    
    const bound_for_define_param = Reflect.apply(
        Function.prototype.bind,
        Object.defineProperties,
        Array.of(Object, self, command_descriptors)
    );

    const bound_for_remove_param = Reflect.apply(
        Function.prototype.bind,
        Array.prototype.forEach,
        Array.of(
            command_all_parameters, 
            bounded_window_delete
        )
    );

    const delayed_remove_binding = Reflect.apply(
        Function.prototype.bind,
        setTimeout,
        Array.of(null, bound_for_remove_param)
    ); 

    Reflect.set(definers, command, bound_for_define_param);
    Reflect.set(cleaners, command, delayed_remove_binding);
};

defineShellCommand('whoami', args => console.log('whoami dispatched:', args));
defineShellCommand('ping', args => console.log('ping dispatched:', args));

// 2. Olası Parametreleri Tanımla (Unix tarzı)
defineCommandParameter('whoami', 'l');
defineCommandParameter('whoami', 'name');
defineCommandParameter('whoami', 'p');
defineCommandParameter('ping', 't');
defineCommandParameter('whoami', 'force');

whoami /name `admin` /force -l [2] -p 