const std = @import("std");

const mach = @import("mach");
const core = mach.core;
const gpu = mach.gpu;
const math = mach.math;
const vec2 = math.vec2;

pub const name = .guecs;

const Self = @This();

triangle: mach.ecs.EntityID,

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

    const triangle = try engine.newEntity();
    try gui_mod.set(triangle, .position, vec2(0, 0));

    guecs.state = .{
        .triangle = triangle,
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
    const clear_color = gpu.Color{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 0.0 };
    try engine.send(.beginPass, .{clear_color});
    try gui_mod.send(.render, .{});
    try engine.send(.endPass, .{});
    try engine.send(.present, .{}); // Present the frame
}
