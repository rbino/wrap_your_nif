const std = @import("std");
const assert = std.debug.assert;
const beam = @import("beam.zig");
const e = beam.e;

pub fn add_two_ints(env: beam.Env, argc: c_int, argv: [*c]const beam.Term) callconv(.C) beam.Term {
    assert(argc == 2);

    // Convert to a slice to leverage Zig out of bound checks
    const argv_slice = @as([*]const beam.Term, @ptrCast(argv))[0..@intCast(argc)];

    const a = beam.get_u32(env, argv_slice[0]) catch {
        return beam.raise_badarg(env);
    };

    const b = beam.get_u32(env, argv_slice[1]) catch {
        return beam.raise_badarg(env);
    };

    const result = a + b;

    return beam.make_u32(env, result);
}

pub fn multiply_three_doubles(env: beam.Env, argc: c_int, argv: [*c]const beam.Term) callconv(.C) beam.Term {
    assert(argc == 3);

    const argv_slice = @as([*]const beam.Term, @ptrCast(argv))[0..@intCast(argc)];

    const a = beam.get_f64(env, argv_slice[0]) catch {
        return beam.raise_badarg(env);
    };

    const b = beam.get_f64(env, argv_slice[1]) catch {
        return beam.raise_badarg(env);
    };

    const c = beam.get_f64(env, argv_slice[2]) catch {
        return beam.raise_badarg(env);
    };

    const result = a * b * c;

    return beam.make_f64(env, result);
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
