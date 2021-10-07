const std = @import("std");
const sling = @import("sling");
const burrow = @import("../burrow.zig");
const Key = sling.input.Key;
const Player = @import("player.zig");
const StaticBrush = @import("staticBrush.zig");

pub const Machine = sling.util.StateMachine(Union, Context);

pub const Context = struct { player: *Player, scene: *sling.Scene };
pub const Union = union(enum) {
    falling: AirState,
    standing: StandState,
};

pub const StandState = struct {
    snapshot: sling.math.Vec2 = .{},
    window: f32 = -1.0,
    pub fn update(self: *StandState, context: Context) ?Union {
        self.window -= sling.dt;
        if (self.window < 0.0) {
            self.snapshot = .{};
        }
        context.player.private.frame = 0;
        if (context.player.private.leniency > 0.0) {
            var next = Union{ .falling = .{ .velocity = self.snapshot } };
            next.falling.jump(context);
            return next;
        }
        return null;
    }
};
pub const AirState = struct {
    velocity: sling.math.Vec2 = .{},
    life: f32 = 0,

    pub fn update(self: *AirState, context: Context) ?Union {
        self.life += sling.dt;

        // Slide jump overrides
        if (context.player.private.slideJumps > 0 and context.player.private.leniency > 0.0) {
            switch (context.player.private.dir) {
                .left => {
                    self.velocity.x = -context.player.private.slidePower;
                },
                .right => {
                    self.velocity.x = context.player.private.slidePower;
                },
                else => {},
            }
            self.velocity.x *= 1.5;
            self.velocity.y = burrow.authoredJumpVelocity(15.0);
            context.player.private.slideJumps -= 1;
            context.player.private.leniency = -1.0;
            context.player.private.dir = .none;
        }

        // Basic tickdowns and calculations
        context.player.private.leniency -= sling.dt;
        const rectangle = Player.size.moved(context.player.position);
        self.velocity = self.velocity.add(burrow.stat.gravity.scale(sling.dt));
        var stateChange: ?Union = null;

        // Sort out state
        var prop = self.velocity.scale(sling.dt);
        context.player.private.flipped = prop.x < 0.0;

        var lifeInt = @floatToInt(usize, self.life*12.5);
        context.player.private.frame = std.math.clamp(lifeInt, 1, 3);
        if (context.scene.has(StaticBrush)) |brushes| {
            for (brushes) |brush| {
                // Continue past brushes that arent collision, or cant possibly collide.
                if (brush.kind != .collision) continue;
                var container = rectangle.expand(prop);
                if (!brush.area.intersectsRect(container)) continue;

                // Actual collision:
                var result: sling.physics.SweepResult = sling.physics.sweepRectEx(rectangle, brush.area, prop);
                if (result.hit) {
                    if (result.hit) {
                        prop = prop.scale(result.time);
                        if (result.normal.x != 0.0) {
                            self.velocity.x = 0;
                        }
                        if (result.normal.y == -1) {
                            if (context.player.private.leniency > 0.0) {
                                self.jump(context);
                                self.life = 0;
                            } else {
                                context.player.private.slideJumps = 0;
                                stateChange = Union{ .standing = .{ .snapshot = self.velocity, .window = burrow.stat.leniency * 0.5 } };
                            }
                        }
                        if (result.normal.y == 1) {
                            self.velocity.y = 0;
                        }
                    }
                }
            }
        }
        context.player.position = context.player.position.add(prop);
        return stateChange;
    }
    pub fn jump(self: *AirState, context: Context) void {
        switch (context.player.private.dir) {
            .left => {
                self.velocity.x -= 60.0;
                self.velocity.y = burrow.authoredJumpVelocity(15.0);
                context.player.private.stepEvent.set("Exertion", 0.3);
                context.player.private.stepEvent.play();
            },
            .right => {
                self.velocity.x += 60.0;
                self.velocity.y = burrow.authoredJumpVelocity(15.0);
                context.player.private.stepEvent.set("Exertion", 0.3);
                context.player.private.stepEvent.play();
            },
            .up => {
                self.velocity.y = burrow.authoredJumpVelocity(50.0);
                context.player.private.stepEvent.set("Exertion", 0.7);
                context.player.private.stepEvent.play();
            },
            .down => {
                context.player.private.slideJumps += 1;
                context.player.private.slidePower = std.math.fabs(self.velocity.x);
                var val = sling.util.remapValueToRange(std.math.fabs(self.velocity.x), 60, 300, true);
                self.velocity.y = burrow.authoredJumpVelocity(230 * val + 20);
                self.velocity.x = 0;
                context.player.private.stepEvent.set("Exertion", 0.7);
                context.player.private.stepEvent.play();
            },
            else => {},
        }
        context.player.private.leniency = -1.0;
        context.player.private.dir = .none;
    }
};
