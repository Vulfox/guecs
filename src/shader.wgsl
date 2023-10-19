// Our vertex shader will recieve these parameters
struct Uniforms {
  // The view * orthographic projection matrix
  view_projection: mat4x4<f32>,
};

@group(0) @binding(0) var<uniform> uniforms : Uniforms;
// Rect model transformation matrices
@group(0) @binding(1) var<storage, read> rect_transforms: array<mat4x4<f32>>;
// Rect sizes, in pixels.
@group(0) @binding(2) var<storage, read> rect_sizes: array<vec2<f32>>;

@vertex fn vertex_main(
    @builtin(vertex_index) VertexIndex : u32
) -> @builtin(position) vec4<f32> {
    let rect_transform = rect_transforms[VertexIndex / 6];
    let rect_size = rect_sizes[VertexIndex / 6];

    let positions = array<vec2<f32>, 6>(
        vec2<f32>(0, 0), // left, bottom
        vec2<f32>(0, 1), // left, top
        vec2<f32>(1, 0), // right, bottom
        vec2<f32>(1, 0), // right, bottom
        vec2<f32>(0, 1), // left, top
        vec2<f32>(1, 1), // right, top
    );

    let pos_2d = positions[VertexIndex % 6];

    var pos = vec4<f32>(pos_2d * rect_size, 0, 1); // normalized -> pixels
    pos = rect_transform * pos; // apply rect transform (pixels)
    pos = uniforms.view_projection * pos;

    return pos;
}

@fragment fn frag_main() -> @location(0) vec4<f32> {
    return vec4<f32>(1.0, 0.0, 0.0, 1.0);
}
