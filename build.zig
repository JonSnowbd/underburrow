const std = @import("std");
const slingBuild = @import("src/deps/slingworks/build.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("underburrow", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    slingBuild.link(exe);
    slingBuild.addBinaryContent("assets") catch unreachable;
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
