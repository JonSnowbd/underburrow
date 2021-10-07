const std = @import("std");
const sling = @import("sling");
const ig = @import("imgui");
const Key = sling.input.Key;
const Self = @This();

const flags =
    ig.ImGuiWindowFlags_NoResize |
    ig.ImGuiWindowFlags_NoTitleBar |
    ig.ImGuiWindowFlags_NoMove;

var mode: enum {
    mainMenu,
    playMenu,
} = .mainMenu;

pub fn roomEnter() void {
    mode = .mainMenu;
}
pub fn roomMethod() void {
    if(sling.scene) |scn| {
        scn.deinit();
        sling.scene = null;
    }
    var exiting: bool = false;
    var io = ig.igGetIO();
    ig.igSetNextWindowSize(.{ .x = std.math.min(440, io.*.DisplaySize.x - 70), .y = io.*.DisplaySize.y - 70 }, ig.ImGuiCond_Always);
    ig.igSetNextWindowPos(io.*.DisplaySize.mul(.{ .x = 0.066, .y = 0.5 }), ig.ImGuiCond_Always, .{ .x = 0.066, .y = 0.5 });

    if (ig.igBegin("Main Menu", null, flags)) {
        switch(mode) {
            .playMenu => {
                exiting = play();
            },
            .mainMenu => {
                exiting = mainM();
            }
        }
    }
    ig.igEnd();

    if (exiting) {
        sling.leaveRoom();
    }
}


fn play() bool {
    ig.igText("Implement me :)");
    return false;
}
fn mainM() bool {
    var size = ig.ImVec2{};
    ig.igGetContentRegionAvail(&size);
    if (ig.igButton("Play", .{ .x = size.x })) {
        mode = .playMenu;
    }
    if (ig.igButton("tutorial", .{ .x = size.x })) {
        sling.scene = sling.Scene.initFromFilepath("content/tutorial.json");
        return true;
    }
    return false;
}