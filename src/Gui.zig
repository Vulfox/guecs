const std = @import("std");

const mach = @import("mach");
const core = mach.core;
const math = mach.math;
const Vec2 = math.Vec2;
const Vec3 = math.Vec3;
const Mat4x4 = math.Mat4x4;
const gpu = mach.gpu;

pub const name = .gui;

pub const components = struct {
    pub const position = Vec3;
    pub const size = Vec2;
    pub const transform = Mat4x4;
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

pub fn init(gui_mod: *mach.Mod(.gui), engine: *mach.Mod(.engine)) !void {
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

pub fn deinit(gui_mod: *mach.Mod(.gui)) !void {
    gui_mod.state.bind_group.release();
    gui_mod.state.uniforms.release();
    gui_mod.state.transforms.release();
    gui_mod.state.sizes.release();

    gui_mod.state.pipeline.release();
}

pub fn guiPreRender(gui_mod: *mach.Mod(.gui), engine: *mach.Mod(.engine)) !void {
    // Update uniform buffer
    const ortho = Mat4x4.ortho(
        -@as(f32, @floatFromInt(core.size().width)) / 2,
        @as(f32, @floatFromInt(core.size().width)) / 2,
        -@as(f32, @floatFromInt(core.size().height)) / 2,
        @as(f32, @floatFromInt(core.size().height)) / 2,
        -0.1,
        100000,
    );
    const uniforms = Uniforms{
        .view_projection = ortho,
    };
    engine.state.encoder.writeBuffer(gui_mod.state.uniforms, 0, &[_]Uniforms{uniforms});

    gui_mod.state.num_of_rects = 0;
    var transforms_offset: usize = 0;
    var sizes_offset: usize = 0;

    var archetypes_iter = engine.entities.query(.{ .all = &.{
        .{ .gui = &.{ .size, .transform } },
    } });
    while (archetypes_iter.next()) |archetype| {
        var transforms = archetype.slice(.gui, .transform);
        var sizes = archetype.slice(.gui, .size);

        engine.state.encoder.writeBuffer(gui_mod.state.transforms, transforms_offset, transforms);
        engine.state.encoder.writeBuffer(gui_mod.state.sizes, sizes_offset, sizes);

        transforms_offset += transforms.len;
        sizes_offset += sizes.len;
        gui_mod.state.num_of_rects += @intCast(transforms.len);
    }
}

pub fn guiRender(gui_mod: *mach.Mod(.gui), engine: *mach.Mod(.engine)) !void {
    const pipeline = gui_mod.state.pipeline;

    // Draw the triangle
    const pass = engine.state.pass;
    pass.setPipeline(pipeline);
    pass.setBindGroup(0, gui_mod.state.bind_group, &.{0});
    pass.draw(6 * gui_mod.state.num_of_rects, 1, 0, 0);
}
