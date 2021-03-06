const std = @import("std");
const sling = @import("sling");
const burrow = @import("../burrow.zig");
const Self = @This();
const Key = sling.input.Key;

// State machine types
const States = @import("playerStates.zig");
const StaticBrush = @import("staticBrush.zig");
const TimeTrial = @import("../scene/timeTrial.zig");

// universal constants for players
const depth = sling.Depth.init(0);
pub const size = sling.math.rect(-8, -50, 16, 50);

const privateState = struct {
    initialPosition: sling.math.Vec2 = .{},
    controlled: bool = true,
    frame: usize = 0,
    textureID: usize = 0,
    state: States.Machine = undefined,
    leniency: f32 = -1.0,
    dir: burrow.Direction = .none,
    flipped: bool = false,
    slideJumps: i32 = 0,
    slidePower: f32 = 0,
    stepEvent: sling.audio.Event = undefined,
};

position: sling.math.Vec2 = .{},
/// Private state hidden from slingworks as it is gameplay instance only logic.
private: privateState = .{},

pub fn assetInit(self: *Self) void {
    self.private.textureID = sling.asset.ensure(sling.asset.Texture, "content/player.png");
}
pub fn gameInit(self: *Self) void {
    sling.render.camera.setZoom(2.0);
    sling.render.camera.setPosition(self.position);
    self.private.initialPosition = self.position;
    self.private.state = States.Machine.init(.{ .falling = .{} });
    self.private.stepEvent = sling.audio.makeEvent("event:/step");
}
pub fn deinit(self: *Self) void {
    self.private.stepEvent.stop();
    self.private.stepEvent.release();
}
pub fn gameUpdate(self: *Self, scene: *sling.Scene) void {
    if (self.private.controlled and Key.a.pressed()) {
        self.private.leniency = burrow.stat.leniency * 0.5;
        self.private.dir = .left;
    }
    if (self.private.controlled and Key.d.pressed()) {
        self.private.leniency = burrow.stat.leniency * 0.5;
        self.private.dir = .right;
    }
    if (self.private.controlled and Key.w.pressed()) {
        self.private.leniency = burrow.stat.leniency * 0.5;
        self.private.dir = .up;
    }
    if (self.private.controlled and Key.s.pressed()) {
        self.private.leniency = burrow.stat.leniency * 0.5;
        self.private.dir = .down;
    }
    if (Key.r.pressed()) {
        self.restart(scene);
    }
    self.private.state.update(.{ .player = self, .scene = scene });

    if(self.private.controlled) {
        // Check if we're in any fancy brushes.
        if(scene.has(StaticBrush)) |brushes| {
            for(brushes) |brush| {
                if(brush.kind == .collision) {
                    continue;
                }
                var rect = size.moved(self.position);
                if(!rect.intersectsRect(brush.area)) {
                    continue;
                }
                switch(brush.kind) {
                    .death => {
                        self.restart(scene);
                    },
                    .finish => {
                        self.private.controlled = false;
                        if(scene.is(TimeTrial)) |timer| {
                            timer.finish();
                        }
                    },
                    else => {}
                }
            }
        }
        self.camera();
    }
    self.render();
}
pub fn editorUpdate(self: *Self, index: usize, scene: *sling.Scene) void {
    const group = scene.objectIndexFor(Self);
    const rect = size.moved(self.position);

    // Select in editor logic.
    if ((Key.lAlt.down() or Key.rAlt.down())) {
        if (rect.containsPoint(sling.input.worldMouse)) {
            sling.render.rectangle(.world, sling.render.debugDepth, rect, sling.Theme.debugWarning.colorFaded(0.2), 2.0 / sling.render.camera.zoom);
            if (Key.lmb.pressed()) {
                scene.editorData.selectedEntity = index;
                scene.editorData.selectedObjectGroup = group;
            }
        }
    }
    const isSelected = group == scene.editorData.selectedObjectGroup and scene.editorData.selectedEntity == index;

    if (isSelected) {
        // selection highlights
        sling.render.rectangle(.world, sling.render.debugDepth, rect, sling.Theme.debugInfo.colorFaded(0.2), 2.0 / sling.render.camera.zoom);
        sling.handles.positionHandle(&self.position, false, null);
    }

    self.render();
}
/// Use slingIntegration to contain configuration into its own type, this is
/// called when you `sling.integrate(type)`
pub fn slingIntegration() void {
    var config = sling.configure(Self);
    config.hide(.private);
    config.ignore(.private);

    config.initMethod(.gameInit, .gameOnly);
    config.deinitMethod(.deinit, .gameOnly);
    config.initMethod(.assetInit, .both);
    config.updateMethod(.gameUpdate, .gameOnly);
    config.updateMethod(.editorUpdate, .editorOnly);
}

// Helper methods:
fn render(self: *Self) void {
    var rect = sling.math.rect(-25,-70,50,70).moved(self.position);
    var frame = sling.math.rect(50 * @intToFloat(f32, self.private.frame), 0, 50, 70);
    if (self.private.flipped) {
        rect.size.x = -rect.size.x;
    }
    sling.render.texture(.world, depth, self.private.textureID, rect.position, rect.size, sling.math.Vec4.white, frame, null);
}

fn restart(self: *Self, scene: *sling.Scene) void {
    self.position = self.private.initialPosition;
    self.private.state = States.Machine.init(.{ .falling = .{} });
    self.private.controlled = true;
    if(scene.is(TimeTrial)) |timer| {
        timer.restart();
    }
    sling.render.camera.setPosition(self.position);
}

fn camera(self: *Self) void {
    var lambda: f32 = 0.99;
    const targ = switch(self.private.state.currentState) {
        .falling => |fall| blk: {
            var adjustment = fall.velocity.scale(1.5);
            // Speed up catchup at >300 vel, and cap out the adjustment at >600 vel
            if(adjustment.length() > 300) {
                lambda = 0.999;
                if(adjustment.length() > 600) {
                    adjustment = adjustment.normalize().scale(600);
                }
            }
            adjustment.y *= 0.05;
            // Todo: Account for grace period on landing to use snapshotted velocity onto adjustment.
            break :blk self.position.add(adjustment);
        },
        else => self.position,
    };
    const source = sling.render.camera.position;
    const result = sling.math.Vec2.lerp(source, targ, 1.0 - std.math.exp(-lambda * sling.unscaledDt));
    sling.render.camera.setPosition(result);
}