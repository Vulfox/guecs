const std = @import("std");
const mach = @import("mach");
const core = mach.core;
const math = mach.math;
const Mat4x4 = math.Mat4x4;

/// calculates the invert matrix when it's possible (returns null otherwise)
/// only works on float matrices
/// https://github.com/ziglibs/zlm/blob/master/src/zlm-generic.zig
pub fn invert(a: Mat4x4) ?Mat4x4 {
    const b00 = a[0][0] * a[1][1] - a[0][1] * a[1][0];
    const b01 = a[0][0] * a[1][2] - a[0][2] * a[1][0];
    const b02 = a[0][0] * a[1][3] - a[0][3] * a[1][0];
    const b03 = a[0][1] * a[1][2] - a[0][2] * a[1][1];
    const b04 = a[0][1] * a[1][3] - a[0][3] * a[1][1];
    const b05 = a[0][2] * a[1][3] - a[0][3] * a[1][2];
    const b06 = a[2][0] * a[3][1] - a[2][1] * a[3][0];
    const b07 = a[2][0] * a[3][2] - a[2][2] * a[3][0];
    const b08 = a[2][0] * a[3][3] - a[2][3] * a[3][0];
    const b09 = a[2][1] * a[3][2] - a[2][2] * a[3][1];
    const b10 = a[2][1] * a[3][3] - a[2][3] * a[3][1];
    const b11 = a[2][2] * a[3][3] - a[2][3] * a[3][2];

    // Calculate the determinant
    var det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;

    if (std.math.approxEqAbs(f32, det, 0, 1e-8)) {
        return null;
    }
    det = 1.0 / det;

    return .{ .v = [_]Vec{
        Vec.init(
            (a[1][1] * b11 - a[1][2] * b10 + a[1][3] * b09) * det,
            (a[0][2] * b10 - a[0][1] * b11 - a[0][3] * b09) * det,
            (a[3][1] * b05 - a[3][2] * b04 + a[3][3] * b03) * det,
            (a[2][2] * b04 - a[2][1] * b05 - a[2][3] * b03) * det,
        ),
        Vec.init(
            (a[1][2] * b08 - a[1][0] * b11 - a[1][3] * b07) * det,
            (a[0][0] * b11 - a[0][2] * b08 + a[0][3] * b07) * det,
            (a[3][2] * b02 - a[3][0] * b05 - a[3][3] * b01) * det,
            (a[2][0] * b05 - a[2][2] * b02 + a[2][3] * b01) * det,
        ),
        Vec.init(
            (a[1][0] * b10 - a[1][1] * b08 + a[1][3] * b06) * det,
            (a[0][1] * b08 - a[0][0] * b10 - a[0][3] * b06) * det,
            (a[3][0] * b04 - a[3][1] * b02 + a[3][3] * b00) * det,
            (a[2][1] * b02 - a[2][0] * b04 - a[2][3] * b00) * det,
        ),
        Vec.init(
            (a[1][1] * b07 - a[1][0] * b09 - a[1][2] * b06) * det,
            (a[0][0] * b09 - a[0][1] * b07 + a[0][2] * b06) * det,
            (a[3][1] * b01 - a[3][0] * b03 - a[3][2] * b00) * det,
            (a[2][0] * b03 - a[2][1] * b01 + a[2][2] * b00) * det,
        ),
    } };
}
