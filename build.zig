const std = @import("std");
const Step = std.Build.Step;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Get the ERTS_INCLUDE_DIR passed by the :build_dot_zig compiler
    // If the variable is not found, fallback to the Elixir shell so this also
    // works when manually invoking zig build or using this from zls
    const erts_include_dir = std.process.getEnvVarOwned(b.allocator, "ERTS_INCLUDE_DIR") catch
        erts_include_dir_from_elixir(b);

    const lib = b.addSharedLibrary(.{
        .name = "wrapyournif",
        .root_source_file = .{ .cwd_relative = "src/wrap_your_nif.zig" },
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    // Add ERTS include dir to the includes
    lib.addSystemIncludePath(.{ .path = erts_include_dir });
    // This is needed to avoid errors at link time on MacOS
    lib.linker_allow_shlib_undefined = true;

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);
}

// Retrieves the location of the ERTS include dir from Elixir
fn erts_include_dir_from_elixir(b: *std.Build) []const u8 {
    const argv = [_][]const u8{
        "elixir",
        "--eval",
        \\["#{:code.root_dir()}", "erts-#{:erlang.system_info(:version)}", "include"]
        \\|> Path.join()
        \\|> IO.write()
    };

    return b.exec(&argv);
}
