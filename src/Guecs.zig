const std = @import("std");

const mach = @import("mach");
const core = mach.core;
const gpu = mach.gpu;
const math = mach.math;
const vec2 = math.vec2;
const vec3 = math.vec3;
const Mat4x4 = math.Mat4x4;

pub const name = .guecs;

const Self = @This();

rect: mach.ecs.EntityID,

pub const Pipeline = enum(u32) {
    default,
};

pub fn init(
    engine: *mach.Mod(.engine),
    guecs: *mach.Mod(.guecs),
    gui_mod: *mach.Mod(.gui),
) !void {
    core.setTitle("Guecs");

    try gui_mod.send(.init, .{});

    const rect = try engine.newEntity();
    try gui_mod.set(rect, .transform, Mat4x4.translate(vec3(100, 100, 0)));
    try gui_mod.set(rect, .size, vec2(150, 100));

    guecs.state = .{
        .rect = rect,
    };
}

pub fn deinit(engine: *mach.Mod(.engine)) !void {
    _ = engine;
}

pub fn tick(
    engine: *mach.Mod(.engine),
    _: *mach.Mod(.guecs),
    gui_mod: *mach.Mod(.gui),
) !void {
    // TODO(engine): event polling should emit ECS events.
    var iter = core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .key_press => |ev| {
                switch (ev.key) {
                    .escape => try engine.send(.exit, .{}),
                    else => {},
                }
            },
            .close => try engine.send(.exit, .{}),
            else => {},
        }
    }

    // Render a frame
    try gui_mod.send(.preRender, .{});

    const clear_color = gpu.Color{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 0.0 };
    try engine.send(.beginPass, .{clear_color});
    try gui_mod.send(.render, .{});
    try engine.send(.endPass, .{});
    try engine.send(.present, .{}); // Present the frame
}
