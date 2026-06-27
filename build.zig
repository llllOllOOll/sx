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

    // test step
    const tests = b.addTest(.{
        .name = "sx-tests",
        .root_module = sx_module,
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
