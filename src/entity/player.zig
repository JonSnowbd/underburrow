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
pub const size = sling.math.rect(-10, -40, 20, 40);
// How much the collider gets inset
const skin: f32 = 1.0;

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

/// Used for shoot maps, or other maps that depend on an initial value that
/// isnt starting in free fall
position: sling.math.Vec2 = .{},
/// Private state hidden from slingworks as it is gameplay instance only logic.
private: privateState = .{},

pub fn assetInit(self: *Self) void {
    self.private.textureID = sling.asset.ensure(sling.asset.Texture, "content/player.png");
}
pub fn gameInit(self: *Self) void {
    sling.render.camera.setZoom(2.0);
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
    if (self.private.controlled and Key.r.pressed()) {
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
        sling.render.camera.setPosition(self.position);
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
    var rect = size.moved(self.position);
    var frame = sling.math.rect(20 * @intToFloat(f32, self.private.frame), 0, 20, 40);
    if (self.private.flipped) {
        rect.size.x = -rect.size.x;
    }
    sling.render.texture(.world, depth, self.private.textureID, rect.position, rect.size, sling.math.Vec4.white, frame, null);
}

fn restart(self: *Self, scene: *sling.Scene) void {
    self.position = self.private.initialPosition;
    self.private.state = States.Machine.init(.{ .falling = .{} });
    if(scene.is(TimeTrial)) |timer| {
        timer.restart();
    }
}