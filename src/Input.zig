const std = @import("std");

const mach = @import("mach");
const core = mach.core;

pub const name = .input;
pub const Mod = mach.Mod(@This());

// TODO: Could probably do some comptime here to make this less manual

pub const components = struct {
    pub const key_press = core.KeyEvent;
    pub const key_repeat = core.KeyEvent;
    pub const key_release = core.KeyEvent;
    pub const char_input = std.meta.TagPayload(core.Event, .char_input);
    pub const mouse_motion = std.meta.TagPayload(core.Event, .mouse_motion); //@TypeOf(core.Event.mouse_motion);
    pub const mouse_press = core.MouseButtonEvent;
    pub const mouse_release = core.MouseButtonEvent;
    pub const mouse_scroll = std.meta.TagPayload(core.Event, .mouse_scroll);
    pub const focus_gained = void;
    pub const focus_lost = void;
    pub const close = void;
};

pub const local = struct {
    pub fn init(_: *Mod, _: *mach.Engine.Mod) !void {}

    pub fn poll(engine: *mach.Engine.Mod, input_mod: *Mod) !void {
        //std.log.warn("inputpoll", .{});
        // Clear previous input events
        var archetypes_iter = engine.entities.query(.{
            .any = &.{
                .{ .input = &.{ .mouse_press, .mouse_release, .mouse_scroll } },
            },
        });
        while (archetypes_iter.next()) |archetype| {
            const ids = archetype.slice(.entity, .id);
            // std.log.warn("IDs: {any}", .{ids});

            for (ids) |id| {
                try engine.entities.remove(id);
            }
        }

        var iter = core.pollEvents();
        while (iter.next()) |event| {
            // const new_event = try engine.newEntity();

            switch (event) {
                // .key_press => |ev| try input_mod.set(new_event, .key_press, ev),
                // .key_repeat => |ev| try input_mod.set(new_event, .key_repeat, ev),
                // .key_release => |ev| try input_mod.set(new_event, .key_release, ev),
                // .char_input => |ev| try input_mod.set(new_event, .char_input, ev),
                // .mouse_motion => |ev| {
                //     const new_event = try engine.newEntity();
                //     try input_mod.set(new_event, .mouse_motion, ev);
                // },
                .mouse_press => |ev| {
                    const new_event = try engine.newEntity();
                    // std.log.warn("mouse_press: {any}", .{new_event});
                    try input_mod.set(new_event, .mouse_press, ev);
                },
                .mouse_release => |ev| {
                    const new_event = try engine.newEntity();
                    // std.log.warn("mouse_release: {any}", .{new_event});
                    try input_mod.set(new_event, .mouse_release, ev);
                },
                .mouse_scroll => |ev| {
                    const new_event = try engine.newEntity();
                    // std.log.warn("mouse_scroll: {any}", .{new_event});
                    try input_mod.set(new_event, .mouse_scroll, ev);
                },
                // .focus_gained => {
                //     const new_event = try engine.newEntity();
                //     try input_mod.set(new_event, .focus_gained, {});
                // },
                // .focus_lost => {
                //     const new_event = try engine.newEntity();
                //     try input_mod.set(new_event, .focus_lost, {});
                // },
                .close => {
                    const new_event = try engine.newEntity();
                    // std.log.warn("input_mod: {any}", .{input_mod.entities.archetypes});
                    std.log.warn("close: {any}", .{new_event});
                    try input_mod.set(new_event, .close, {});
                },
                else => {},
            }
        }
    }
};
// pub fn init(_: *Mod, _: *mach.Engine.Mod) !void {}
