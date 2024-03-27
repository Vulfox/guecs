const std = @import("std");

const mach = @import("mach");
const core = mach.core;
const gpu = mach.gpu;
const math = mach.math;
const vec2 = math.vec2;
const vec3 = math.vec3;
const Mat4x4 = math.Mat4x4;

pub const name = .guecs;
pub const Mod = mach.Mod(@This());

const Gui = @import("Gui.zig");
const Input = @import("Input.zig");

const Self = @This();

rect: mach.ecs.EntityID,

pub const Pipeline = enum(u32) {
    default,
};

pub fn init(
    engine: *mach.Engine.Mod,
    guecs: *Mod,
    gui_mod: *Gui.Mod,
    input_mod: *Input.Mod,
) !void {
    core.setTitle("Guecs");

    try input_mod.send(.init, .{});
    try gui_mod.send(.init, .{});

    const rect = try engine.newEntity();
    try gui_mod.set(rect, .transform, Mat4x4.translate(vec3(100, 100, 0)));
    try gui_mod.set(rect, .size, vec2(150, 100));
    try gui_mod.set(rect, .clickable, {});
    try gui_mod.set(rect, .visible, {});

    guecs.state = .{
        .rect = rect,
    };
}

pub fn deinit(engine: *mach.Engine.Mod) !void {
    _ = engine;
}

pub fn tick(
    engine: *mach.Engine.Mod,
    _: *Mod,
    input_mod: *Input.Mod,
    gui_mod: *Gui.Mod,
) !void {
    try input_mod.send(.poll, .{});

    // Check if we need to close first.
    // For real application, should probably utilize an input -> actions abstraction, so Close and ESC could trigger -> Close Action
    var archetypes_iter = engine.entities.query(.{ .all = &.{
        .{ .input = &.{.close} },
    } });
    if (archetypes_iter.next() != null) try engine.send(.exit, .{});

    //try gui_mod.send(.handleInput, .{});

    // Render a frame
    try gui_mod.send(.preRender, .{});

    const clear_color = gpu.Color{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 0.0 };
    try engine.send(.beginPass, .{clear_color});
    try gui_mod.send(.render, .{});
    try engine.send(.endPass, .{});
    try engine.send(.present, .{}); // Present the frame
}
