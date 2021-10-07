const std = @import("std");
const sling = @import("sling");
const burrow = @import("../burrow.zig");
const Self = @This();

pub const Kind = enum {
    none,
    collision,
    checkpoint,
    finish,
    death,
};

position: sling.math.Vec2 = .{},
editorName: [64:0]u8 = std.mem.zeroes([64:0]u8),
depth: sling.Depth = sling.Depth.init(0),
color: sling.math.Vec4 = sling.math.Vec4.white,
fontPath: ?[256:0]u8 = null,
message: [512:0]u8 = std.mem.zeroes([512:0]u8),
editorFontPath: [256:0]u8 = std.mem.zeroes([256:0]u8),

pub fn editorInit(self: *Self) void {
    if(std.mem.lenZ(self.editorName) == 0) {
        for("New Text") |char, i| {
            self.editorName[i] = char;
        }
    }
}
pub fn update(self: *Self) void {
    self.render();
}

pub fn getName(self: *Self) []const u8 {
    return std.mem.spanZ(&self.editorName);
}

pub fn extension(self: *Self) void {
    const ig = @import("imgui");
    ig.igSeparator();
    ig.igText("Font settings");
    if (self.fontPath) |_| {
        if (ig.igButton("Remove Font", .{})) {
            self.fontPath = null;
            return;
        }
    } else {
        _ = sling.util.igEdit("Font Path", &self.editorFontPath);
        if (ig.igButton("Apply", .{})) {
            self.fontPath = std.mem.zeroes([256:0]u8);
            std.mem.copy(u8, &self.fontPath.?, std.mem.spanZ(&self.editorFontPath));
        }
    }
}

pub fn slingIntegration() void {
    var config = sling.configure(Self);
    config.initMethod(.editorInit, .editorOnly);
    config.updateMethod(.update, .both);
    config.hide(.fontPath);
    config.hide(.editorFontPath);
    config.ignore(.editorFontPath);
    config.editorExtension(.extension);
    config.nameMethod(.getName);
}

fn render(self: *Self) void {
    var message = std.mem.spanZ(&self.message);
    if(message.len == 0) {
        return;
    }
    if (self.fontPath) |font| {
        const id = sling.asset.ensure(sling.asset.Font, std.mem.spanZ(&font));
        sling.render.text(.world, self.depth, id, self.position, message, self.color, null);
    }
}
