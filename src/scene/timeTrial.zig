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

    const flags = ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove;
    var io = ig.igGetIO();
    ig.igSetNextWindowSize(.{.x=io.*.DisplaySize.x*0.5,.y=100}, ig.ImGuiCond_Always);
    ig.igSetNextWindowPos(.{.y=io.*.DisplaySize.y}, ig.ImGuiCond_Always, .{.x=0,.y=1.0});
    if(ig.igBegin("Stats", null, flags)) {
        sling.zt.custom_components.ztText("TIME: {d:.2}s", .{self.currentTime});
        if(self.finished) {
            sling.zt.custom_components.ztText("You finished with the time {d:.2}s.", .{self.currentTime});
            if(ig.igButton("Return to Menu", .{})) {
                sling.enterRoomString("Main Menu");
            }
        }
    }
    ig.igEnd();
}

pub fn begin(self: *Self) void {
    self.currentTime = -2;
    self.playing = true;
    sling.timeScale = 0.0;
}
pub fn restart(self: *Self) void {
    self.begin();
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
