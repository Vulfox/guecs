const std = @import("std");

const mach = @import("mach");
const core = mach.core;
const math = mach.math;
const Vec2 = math.Vec2;
const vec2 = math.vec2;
const Vec3 = math.Vec3;
const Mat4x4 = math.Mat4x4;
const gpu = mach.gpu;

pub const name = .gui;
pub const Mod = mach.Mod(@This());

pub const components = struct {
    // pub const position = Vec3;
    pub const size = Vec2;
    pub const transform = Mat4x4;

    pub const clickable = void;
    pub const visible = void;
};

const Uniforms = extern struct {
    view_projection: Mat4x4 align(16),
};

pipeline: *gpu.RenderPipeline,
bind_group: *gpu.BindGroup,
uniforms: *gpu.Buffer,

num_of_rects: u32 = 0,
transforms: *gpu.Buffer,
sizes: *gpu.Buffer,

pub const local = struct {
    pub fn init(gui_mod: *Mod, engine: *mach.Engine.Mod) !void {
        const device = engine.state.device;

        // Storage buffers
        const rect_buffer_cap = 1024 * 512; // TODO: allow user to specify preallocation
        const transforms = device.createBuffer(&.{
            .usage = .{ .storage = true, .copy_dst = true },
            .size = @sizeOf(Mat4x4) * rect_buffer_cap,
            .mapped_at_creation = .false,
        });
        const sizes = device.createBuffer(&.{
            .usage = .{ .storage = true, .copy_dst = true },
            .size = @sizeOf(Vec2) * rect_buffer_cap,
            .mapped_at_creation = .false,
        });

        const uniforms = device.createBuffer(&.{
            .usage = .{ .copy_dst = true, .uniform = true },
            .size = @sizeOf(Uniforms),
            .mapped_at_creation = .false,
        });
        const bind_group_layout = device.createBindGroupLayout(
            &gpu.BindGroupLayout.Descriptor.init(.{
                .entries = &.{
                    gpu.BindGroupLayout.Entry.buffer(0, .{ .vertex = true }, .uniform, true, 64), // TODO: Mach Sprite doesn't do this, but I get a dynamic offset error
                    gpu.BindGroupLayout.Entry.buffer(1, .{ .vertex = true }, .read_only_storage, false, 0),
                    gpu.BindGroupLayout.Entry.buffer(2, .{ .vertex = true }, .read_only_storage, false, 0),
                },
            }),
        );
        defer bind_group_layout.release();

        const bind_group = device.createBindGroup(
            &gpu.BindGroup.Descriptor.init(.{
                .layout = bind_group_layout,
                .entries = &.{
                    gpu.BindGroup.Entry.buffer(0, uniforms, 0, @sizeOf(Uniforms)),
                    gpu.BindGroup.Entry.buffer(1, transforms, 0, @sizeOf(Vec2) * rect_buffer_cap),
                    gpu.BindGroup.Entry.buffer(2, sizes, 0, @sizeOf(Vec2) * rect_buffer_cap),
                },
            }),
        );

        const shader_module = device.createShaderModuleWGSL("shader.wgsl", @embedFile("shader.wgsl"));
        defer shader_module.release();

        // Fragment state
        const blend = gpu.BlendState{};
        const color_target = gpu.ColorTargetState{
            .format = mach.core.descriptor.format,
            .blend = &blend,
            .write_mask = gpu.ColorWriteMaskFlags.all,
        };
        const fragment = gpu.FragmentState.init(.{
            .module = shader_module,
            .entry_point = "frag_main",
            .targets = &.{color_target},
        });

        const bind_group_layouts = [_]*gpu.BindGroupLayout{bind_group_layout};
        const pipeline_layout = device.createPipelineLayout(&gpu.PipelineLayout.Descriptor.init(.{
            .bind_group_layouts = &bind_group_layouts,
        }));
        defer pipeline_layout.release();

        const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
            .fragment = &fragment,
            .layout = pipeline_layout,
            .vertex = gpu.VertexState{
                .module = shader_module,
                .entry_point = "vertex_main",
            },
        };

        gui_mod.state.pipeline = device.createRenderPipeline(&pipeline_descriptor);
        gui_mod.state.bind_group = bind_group;
        gui_mod.state.uniforms = uniforms;
        gui_mod.state.transforms = transforms;
        gui_mod.state.sizes = sizes;
    }

    pub fn handleInput(engine: *mach.Engine.Mod) !void {
        // Grab all visible and clickable rects
        var archetypes_iter = engine.entities.query(.{ .all = &.{
            .{ .gui = &.{ .visible, .clickable, .size, .transform } },
        } });
        var input_iter = engine.entities.query(.{ .all = &.{
            .{ .input = &.{.mouse_press} },
        } });

        var mouse_press_pos: Vec2 = undefined;
        while (input_iter.next()) |input| {
            const mouse_presses = input.slice(.input, .mouse_press);
            if (mouse_presses.len > 0) mouse_press_pos = vec2(@as(f32, @floatCast(mouse_presses[0].pos.x)), @as(f32, @floatCast(mouse_presses[0].pos.y)));
        }

        while (archetypes_iter.next()) |archetype| {
            const transforms = archetype.slice(.gui, .transform);
            const sizes = archetype.slice(.gui, .size);

            for (transforms, sizes) |t, size| {
                const rect_pos = t.translation();
                // std.log.warn("translate: {any}", .{t.translation()});
                // std.log.warn("size: {any}", .{s});

                if (mouse_press_pos.x() > rect_pos.x() and mouse_press_pos.x() < rect_pos.x() + size.x() and
                    mouse_press_pos.y() > rect_pos.y() and mouse_press_pos.y() < rect_pos.y() + size.y())
                {
                    std.log.warn("clicked", .{});
                }
            }
        }
    }

    pub fn preRender(gui_mod: *Mod, engine: *mach.Engine.Mod) !void {
        // Update uniform buffer
        // Set 0,0 to top-left

        const window_size = mach.core.size();
        const proj = Mat4x4.projection2D(.{
            .left = 0,
            .right = @floatFromInt(window_size.width),
            .bottom = @floatFromInt(window_size.height),
            .top = 0,
            .near = -0.1,
            .far = 100000,
        });

        const uniforms = Uniforms{
            .view_projection = proj,
        };
        engine.state.encoder.writeBuffer(gui_mod.state.uniforms, 0, &[_]Uniforms{uniforms});

        gui_mod.state.num_of_rects = 0;
        var transforms_offset: usize = 0;
        var sizes_offset: usize = 0;

        var archetypes_iter = engine.entities.query(.{ .all = &.{
            .{ .gui = &.{ .size, .transform } },
        } });
        while (archetypes_iter.next()) |archetype| {
            const transforms = archetype.slice(.gui, .transform);
            const sizes = archetype.slice(.gui, .size);

            engine.state.encoder.writeBuffer(gui_mod.state.transforms, transforms_offset, transforms);
            engine.state.encoder.writeBuffer(gui_mod.state.sizes, sizes_offset, sizes);

            transforms_offset += transforms.len;
            sizes_offset += sizes.len;
            gui_mod.state.num_of_rects += @intCast(transforms.len);
        }
    }

    pub fn render(gui_mod: *Mod, engine: *mach.Engine.Mod) !void {
        const pipeline = gui_mod.state.pipeline;

        // Draw the triangle
        const pass = engine.state.pass;
        pass.setPipeline(pipeline);
        pass.setBindGroup(0, gui_mod.state.bind_group, &.{0});
        pass.draw(6 * gui_mod.state.num_of_rects, 1, 0, 0);
    }
};

pub fn deinit(gui_mod: *Mod) !void {
    gui_mod.state.bind_group.release();
    gui_mod.state.uniforms.release();
    gui_mod.state.transforms.release();
    gui_mod.state.sizes.release();

    gui_mod.state.pipeline.release();
}
