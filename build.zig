const std = @import("std");
const Build = std.Build;
const ResolvedTarget = Build.ResolvedTarget;
const OptimizeMode = std.builtin.OptimizeMode;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const test_step = b.step("test", "Run bindings tests");

    // rocksdb itself as a zig module
    const libmdbx_mod = buildLibmdbx(b, target, optimize);

    const bindings_mod = b.addModule("libmdbx-bindings", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/lib.zig"),
    });

    bindings_mod.addImport("libmdbx", libmdbx_mod);
}

fn buildLibmdbx(b: *Build, target: ResolvedTarget, optimize: OptimizeMode) *Build.Module {
    const libmdbx = b.dependency("libmdbx", .{});

    const translate_c = b.addTranslateC(.{
        .root_source_file = libmdbx.path("mdbx.h"),
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("libmdbx", .{
        .root_source_file = translate_c.getOutput(),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });

    const libmdbx_a = try buildLibMdbxStatic(b, target, optimize);
    mod.addIncludePath(libmdbx.path("src"));
    mod.linkLibrary(libmdbx_a);
    return mod;
}

fn buildLibMdbxStatic(b: *Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !*Build.Step.Compile {
    const t = target.result;
    const libmdbx_dep = b.dependency("libmdbx", .{});

    const libmdbx_a = b.addStaticLibrary(.{
        .name = "libmdbx",
        .target = target,
        .optimize = optimize,
    });

    libmdbx_a.addIncludePath(libmdbx_dep.path("src"));

    const build_version = b.addConfigHeader(.{
        .style = .{ .cmake = libmdbx_dep.path("src/version.c.in") },
        .include_path = "src/version.c",
    }, .{
        .MDBX_VERSION_MAJOR = 0,
        .MDBX_VERSION_MINOR = 11,
        .MDBX_VERSION_RELEASE = "0.11.6",
        .MDBX_VERSION_REVISION = "0.11.6",
        .MDBX_GIT_TIMESTAMP = "",
        .MDBX_GIT_TREE = "",
        .MDBX_GIT_COMMIT = "",
        .MDBX_GIT_DESCRIBE = "",
    });
    libmdbx_a.addCSourceFile(.{ .file = build_version.getOutput() });

    libmdbx_a.addCSourceFiles(.{
        .root = libmdbx_dep.path("."),
        .files = &.{
            "src/alloy.c",
            "src/core.c",
            "src/mdbx_chk.c",
            "src/mdbx_copy.c",
            "src/mdbx_drop.c",
            "src/mdbx_dump.c",
            "src/mdbx_load.c",
            "src/mdbx_stat.c",
            "src/osal.c",
            "src/wingetopt.c",
        },
        .flags = &.{
            "-std=c11",
        },
    });

    if (t.os.tag != .windows) {
        libmdbx_a.addCSourceFiles(.{
            .root = libmdbx_dep.path("."),
            .files = &.{
                "src/lck-posix.c",
            },
            .flags = &.{
                "-std=c11",
            },
        });
    } else {
        libmdbx_a.addCSourceFiles(.{
            .root = libmdbx_dep.path("."),
            .files = &.{
                "src/lck-windows.c",
            },
            .flags = &.{
                "-std=c11",
            },
        });
    }

    b.installArtifact(libmdbx_a);

    return libmdbx_a;
}
