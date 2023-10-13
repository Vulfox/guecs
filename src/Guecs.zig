const std = @import("std");
const mach = @import("mach");
const core = mach.core;
pub const name = .guecs;

pub const Pipeline = enum(u32) {
    default,
};

pub fn init(
    _: *mach.Mod(.engine),
    _: *mach.Mod(.guecs),
) !void {
    core.setTitle("Guecs");
}

pub fn deinit(engine: *mach.Mod(.engine)) !void {
    _ = engine;
}

pub fn tick(
    engine: *mach.Mod(.engine),
    _: *mach.Mod(.guecs),
) !void {
    // TODO(engine): event polling should emit ECS events.
    var iter = core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .close => try engine.send(.exit, .{}),
            else => {},
        }
    }
}
