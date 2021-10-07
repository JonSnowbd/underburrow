const std = @import("std");
const sling = @import("sling");
const burrow = @import("../burrow.zig");
const Key = sling.input.Key;
const Self = @This();

pub const Kind = enum {
    none,
    collision,
    checkpoint,
    finish,
    death,
};

editorName: [64:0]u8 = std.mem.zeroes([64:0]u8),
area: sling.math.Rect = sling.math.rect(0, 0, 200, 100),
depth: sling.Depth = sling.Depth.init(0),
color: sling.math.Vec4 = sling.math.Vec4.white,
kind: Kind = .collision,
decoration: ?[256:0]u8 = null,
decorationTileSize: f32 = 16,
editorDecorationPath: [256:0]u8 = std.mem.zeroes([256:0]u8),

pub fn editorInit(self: *Self) void {
    if(std.mem.lenZ(self.editorName) == 0) {
        for("New Brush") |char, i| {
            self.editorName[i] = char;
        }
    }
}
pub fn gameUpdate(self: *Self) void {
    self.render();
}
pub fn editorUpdate(self: *Self, scene: *sling.Scene, index: usize) void {
    const group = scene.objectIndexFor(Self);

    // If alt clicked, selected this entity.
    if ((Key.lAlt.down() or Key.rAlt.down())) {
        if (self.area.containsPoint(sling.input.worldMouse)) {
            sling.render.rectangle(.world, sling.render.debugDepth, self.area, sling.Theme.debugInfo.colorFaded(0.2), 2.0 / sling.render.camera.zoom);
            if (Key.lmb.pressed()) {
                scene.editorData.selectedEntity = index;
                scene.editorData.selectedObjectGroup = group;
            }
        }
    }

    // Render in editor representation of the brush
    const isSelected = group == scene.editorData.selectedObjectGroup and scene.editorData.selectedEntity == index;

    if (self.decoration) |_| {
        self.render();
    } else {
        var color = self.color;
        color.w *= 0.3;
        sling.render.rectangle(.world, sling.render.debugDepth, self.area, color, -1);
    }
    if (isSelected) {
        sling.render.rectangle(.world, sling.render.debugDepth, self.area, self.color, 2.0 / sling.render.camera.zoom);
        sling.handles.rectangleHandle(&self.area);
    }
}

pub fn getName(self: *Self) []const u8 {
    return std.mem.spanZ(&self.editorName);
}

pub fn extension(self: *Self) void {
    const ig = @import("imgui");
    ig.igSeparator();
    ig.igText("Decor settings");
    if (self.decoration) |_| {
        if (ig.igButton("Remove Decor", .{})) {
            self.decoration = null;
            return;
        }
        _ = sling.util.igEdit("Tile Size", &self.decorationTileSize);
    } else {
        _ = sling.util.igEdit("Decor Path", &self.editorDecorationPath);
        if (ig.igButton("Apply", .{})) {
            self.decoration = std.mem.zeroes([256:0]u8);
            std.mem.copy(u8, &self.decoration.?, std.mem.spanZ(&self.editorDecorationPath));
        }
    }
}

pub fn slingIntegration() void {
    var config = sling.configure(Self);
    config.initMethod(.editorInit, .editorOnly);
    config.updateMethod(.gameUpdate, .gameOnly);
    config.updateMethod(.editorUpdate, .editorOnly);
    config.hide(.decoration);
    config.hide(.decorationTileSize);
    config.hide(.editorDecorationPath);
    config.ignore(.editorDecorationPath);
    config.editorExtension(.extension);
    config.nameMethod(.getName);
}

fn render(self: *Self) void {
    if (self.decoration) |decorPath| {
        const id = sling.asset.ensure(sling.asset.Texture, std.mem.spanZ(&decorPath));
        const patch = sling.Patch{
            .subRect = sling.math.rect(0, 0, self.decorationTileSize * 3, self.decorationTileSize * 3),
            .left = self.decorationTileSize,
            .top = self.decorationTileSize,
            .right = self.decorationTileSize,
            .bottom = self.decorationTileSize,
        };
        sling.render.patch(.world, self.depth, patch, id, self.area, self.color);
    }
}
