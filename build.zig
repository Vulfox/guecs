const std = @import("std");

const mach = @import("mach");
const mach_freetype = @import("mach_freetype");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mach_dep = b.dependency("mach", .{
        .target = target,
        .optimize = optimize,
    });
    const mach_freetype_dep = b.dependency("mach_freetype", .{
        .target = target,
        .optimize = optimize,
    });

    const app = try mach.App.init(b, .{
        .name = "guecs",
        .src = "src/main.zig",
        .target = target,
        .optimize = optimize,
        .mach_builder = mach_dep.builder,
        .deps = &[_]std.build.ModuleDependency{
            .{ .name = "mach-freetype", .module = mach_freetype_dep.module("mach-freetype") },
        },
    });
    if (b.args) |args| app.run.addArgs(args);

    mach_freetype.linkFreetype(mach_freetype_dep.builder, app.compile);

    // Test Step
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&app.run.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
