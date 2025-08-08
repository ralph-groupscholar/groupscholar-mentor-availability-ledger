const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "groupscholar-mentor-availability-ledger",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const include_path = std.process.getEnvVarOwned(b.allocator, "PG_INCLUDE_PATH") catch null;
    if (include_path) |path| {
        defer b.allocator.free(path);
        exe.addIncludePath(.{ .cwd_relative = path });
    } else {
        exe.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
        exe.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
    }

    const lib_path = std.process.getEnvVarOwned(b.allocator, "PG_LIB_PATH") catch null;
    if (lib_path) |path| {
        defer b.allocator.free(path);
        exe.addLibraryPath(.{ .cwd_relative = path });
    } else {
        exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
        exe.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
    }

    exe.linkSystemLibrary("pq");
    exe.linkLibC();

    b.installArtifact(exe);

    const validation_module = b.createModule(.{
        .root_source_file = b.path("src/validation.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tests = b.addTest(.{
        .root_module = validation_module,
    });
    tests.linkLibC();

    const test_run = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&test_run.step);
}
