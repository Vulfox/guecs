const std = @import("std");

const mach = @import("mach");
const math = mach.math;
const Vec2 = math.Vec2;
const gpu = mach.gpu;

pub const name = .gui;

pub const components = struct {
    pub const position = Vec2;
    pub const size = Vec2;
};

pipeline: *gpu.RenderPipeline,

pub fn init(gui_mod: *mach.Mod(.gui), engine: *mach.Mod(.engine)) !void {
    const device = engine.state.device;

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
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &fragment,
        .vertex = gpu.VertexState{
            .module = shader_module,
            .entry_point = "vertex_main",
        },
    };

    gui_mod.state.pipeline = device.createRenderPipeline(&pipeline_descriptor);
}

pub fn deinit(gui_mod: *mach.Mod(.gui)) !void {
    gui_mod.state.pipeline.release();
}

pub fn guiRender(gui_mod: *mach.Mod(.gui), engine: *mach.Mod(.engine)) !void {
    const pipeline = gui_mod.state.pipeline;

    // Draw the triangle
    const pass = engine.state.pass;
    pass.setPipeline(pipeline);
    pass.draw(3, 1, 0, 0);
}
