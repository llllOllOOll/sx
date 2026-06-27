const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const sx_module = b.createModule(.{
        .root_source_file = b.path("src/sx.zig"),
    });

    const exe = b.addExecutable(.{
        .name = "hello",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
        }),
    });
    exe.root_module.addImport("sx", sx_module);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run Application");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.addPassthruArgs();
}
