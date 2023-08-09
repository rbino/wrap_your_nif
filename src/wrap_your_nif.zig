const std = @import("std");
const assert = std.debug.assert;
const beam = @import("beam.zig");
const e = beam.e;

pub const add_two_ints = make_nif_wrapper(add_two_ints_impl);

fn add_two_ints_impl(env: beam.Env, a: u32, b: u32) beam.Term {
    const result = a + b;

    return beam.make_u32(env, result);
}

pub const multiply_three_doubles = make_nif_wrapper(multiply_three_doubles_impl);

fn multiply_three_doubles_impl(env: beam.Env, a: f64, b: f64, c: f64) beam.Term {
    const result = a * b * c;

    return beam.make_f64(env, result);
}

const Nif = *const fn (beam.Env, argc: c_int, argv: [*c]const beam.Term) callconv(.C) beam.Term;

fn make_nif_wrapper(comptime fun: anytype) Nif {
    const Function = @TypeOf(fun);

    const function_info = switch (@typeInfo(Function)) {
        .Fn => |f| f,
        else => @compileError("Only functions can be wrapped"),
    };

    const params = function_info.params;
    // Env is not counted in argc, so subtract one
    const expected_argc = params.len - 1;

    return struct {
        pub fn wrapper(
            env: beam.Env,
            argc: c_int,
            argv: [*c]const beam.Term,
        ) callconv(.C) beam.Term {
            if (argc != expected_argc) @panic("NIF called with the wrong number of arguments");

            const argv_slice = @as([*]const beam.Term, @ptrCast(argv))[0..@intCast(argc)];

            // This creates a tuple with the right dimensions and types to store
            // the arguments of the passed function type
            var args: std.meta.ArgsTuple(Function) = undefined;
            // Populate the args
            inline for (&args, 0..) |*arg, arg_idx| {
                if (arg_idx == 0) {
                    // The first argument is the environment
                    arg.* = env;
                    continue;
                }

                // There is an offset between args and argv since argv doesn't
                // contain the env
                const argv_idx = arg_idx - 1;
                // For all the other arguments, extract them based on their type
                const ArgType = @TypeOf(arg.*);
                arg.* = get_arg_from_term(ArgType, env, argv_slice[argv_idx]) catch
                    return beam.raise_badarg(env);
            }

            return @call(.auto, fun, args);
        }
    }.wrapper;
}

fn get_arg_from_term(comptime T: type, env: beam.Env, term: beam.Term) !T {
    // These are what we currently need, the need to add new types to the switch will be caught
    // by the compileError below
    return switch (T) {
        u32 => try beam.get_u32(env, term),
        f64 => try beam.get_f64(env, term),
        else => @compileError("Type " ++ @typeName(T) ++ " is not handled by get_arg_from_term"),
    };
}

// NIF initialization boilerplate below
export var __exported_nifs__ = [_]e.ErlNifFunc{
    e.ErlNifFunc{
        .name = "add_two_ints",
        .arity = 2,
        .fptr = add_two_ints,
        .flags = 0,
    },
    e.ErlNifFunc{
        .name = "multiply_three_doubles",
        .arity = 3,
        .fptr = multiply_three_doubles,
        .flags = 0,
    },
};

const entry = e.ErlNifEntry{
    .major = 2,
    .minor = 16,
    .name = "Elixir.WrapYourNif",
    .num_of_funcs = __exported_nifs__.len,
    .funcs = &(__exported_nifs__[0]),
    .load = null,
    .reload = null,
    .upgrade = null,
    .unload = null,
    .vm_variant = "beam.vanilla",
    .options = 1,
    .sizeof_ErlNifResourceTypeInit = @sizeOf(e.ErlNifResourceTypeInit),
    .min_erts = "erts-13.1.2",
};

export fn nif_init() *const e.ErlNifEntry {
    return &entry;
}
