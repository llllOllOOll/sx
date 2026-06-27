const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // expose sx module for external consumers
    const sx_module = b.addModule("sx", .{
        .root_source_file = b.path("src/sx.zig"),
        .target = target,
        .optimize = optimize,
    });

    // example executable
    const exe_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_module.addImport("sx", sx_module);
    const exe = b.addExecutable(.{
        .name = "sx-example",
        .root_module = exe_module,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.addPassthruArgs();
    const run_step = b.step("run", "Run the example");
    run_step.dependOn(&run_cmd.step);

    // test step
    const tests = b.addTest(.{
        .name = "sx-tests",
        .root_module = sx_module,
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
