const std = @import("std");
const sling = @import("sling");
const ig = @import("imgui");
const Key = sling.input.Key;
const Self = @This();

// State
playing: bool = false,
finished: bool = false,
currentTime: f32 = 0.0,

// Medals
goldMedal: f32 = 0.0,
silverMedal: f32 = 0.0,
bronzeMedal: f32 = 0.0,

pub fn gameInit(self: *Self) void {
    self.begin();
}
pub fn gameDeinit(self: *Self) void {
    _ = self;
    sling.timeScale = 1.0;
}
pub fn update(self: *Self) void {
    if (self.playing) {
        self.currentTime += sling.unscaledDt;
        if(self.currentTime > 0.0) {
            sling.timeScale = 1.0;
        }
    }
    sling.render.text(.screen, sling.Depth.init(0), 0, .{.x=10,.y=10}, "Time Trial", sling.math.Vec4.white, null);

    var io = ig.igGetIO();
    sling.render.text(.screen, sling.Depth.init(0), 0, .{.x=io.*.DisplaySize.x-10,.y=10}, "A/D - Momentum Hops\nW - Height Vault\nS - Updraft", sling.math.Vec4.white, sling.math.vec2(1.0,0.0));

    if(self.finished) {
        const blackout = sling.math.vec4(0.0, 0.0, 0.0, 0.3);
        sling.render.rectangle(.screen, sling.Depth.init(10.0), .{.size=io.*.DisplaySize}, blackout, null);

        var timer = sling.util.tempFmt("Record!\n{d:.3}s", .{self.currentTime});
        sling.render.text(.screen, sling.Depth.init(0), 0, io.*.DisplaySize.scale(0.5), timer, sling.math.Vec4.white, sling.math.Vec2{.x=0.5,.y=0.5});
    } else {
        var timer = sling.util.tempFmt("{d:.2}", .{self.currentTime});
        sling.render.text(.screen, sling.Depth.init(0), 0, .{.x=15,.y=41}, timer, sling.math.Vec4.white, null);
    }
}

pub fn begin(self: *Self) void {
    self.currentTime = -2;
    self.playing = true;
    sling.timeScale = 0.0;
}
pub fn restart(self: *Self) void {
    self.begin();
    self.finished = false;
}
pub fn finish(self: *Self) void {
    self.playing = false;
    self.finished = true;
    sling.timeScale = 0.15;
}

pub fn slingIntegration() void {
    var config = sling.configure(Self);
    config.initMethod(.gameInit, .gameOnly);
    config.deinitMethod(.gameDeinit, .gameOnly);
    config.hide(.currentTime);
    config.hide(.playing);
    config.updateMethod(.update, .gameOnly);
}
