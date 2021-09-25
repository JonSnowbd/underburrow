const std = @import("std");
const sling = @import("sling");

pub const Direction = enum { none, left, up, right, down };
pub const stat = struct {
    pub const leniency: f32 = 0.125;
    pub const gravity: sling.math.Vec2 = .{ .y = 981.0 };
};
pub fn authoredJumpVelocity(apexHeight: f32) f32 {
    return -std.math.sqrt(2.0 * stat.gravity.y * apexHeight);
}
