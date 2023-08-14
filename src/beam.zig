pub const e = @cImport(@cInclude("erl_nif.h"));

pub const Env = ?*e.ErlNifEnv;
pub const Term = e.ERL_NIF_TERM;

pub fn get_u32(env: Env, term: Term) !u32 {
    var result: c_uint = undefined;
    if (e.enif_get_uint(env, term, &result) == 0) {
        return error.ArgumentError;
    }
    return @intCast(result);
}

pub fn get_f64(env: Env, term: Term) !f64 {
    var result: f64 = undefined;
    if (e.enif_get_double(env, term, &result) == 0) {
        return error.ArgumentError;
    }
    return result;
}

pub fn make_u32(env: Env, value: u32) Term {
    return e.enif_make_uint(env, @intCast(value));
}

pub fn make_f64(env: Env, value: f64) Term {
    return e.enif_make_double(env, value);
}

pub fn raise_badarg(env: Env) Term {
    return e.enif_make_badarg(env);
}
