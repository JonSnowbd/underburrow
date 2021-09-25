const std = @import("std");
const sling = @import("sling");
const ig = @import("imgui");
const Key = sling.input.Key;

const Player = @import("entity/player.zig");
const StaticBrush = @import("entity/staticBrush.zig");
const TimeTrial = @import("scene/timeTrial.zig");
const SelectionMenu = @import("rooms/selector.zig");

var ambience: sling.audio.Event = undefined;
var volume: f32 = 0.5;

pub fn main() anyerror!void {
    sling.addStaticInit(initialization);

    sling.integrate(Player);
    sling.integrate(StaticBrush);
    sling.integrate(TimeTrial);
    sling.register.room(SelectionMenu.roomMethod, "Main Menu", SelectionMenu.roomEnter, null);
    sling.register.scene(TimeTrial, .{ Player, StaticBrush });

    sling.run();
}

fn initialization() void {
    applyStyle();

    sling.setWindowTitle("The Underburrow");
    sling.setWindowIcon("icon.png");

    if (!sling.inEditor) {
        sling.settings.initialScene = null;
        sling.enterRoomString("Main Menu");
    }

    // You want to do audio loading and such in init at the earliest
    sling.audio.loadBank("content/audio/Master.bank");
    sling.audio.loadBank("content/audio/Master.strings.bank");

    ambience = sling.audio.makeEvent("event:/caveAmbience");
    ambience.setVolume(volume*0.2);
    ambience.play();
}

fn applyStyle() void {
    var style = ig.igGetStyle();
    ig.igStyleColorsClassic(style);

    sling.setEditorFontBytes(@embedFile("deps/ubuntu_mono.ttf"), 15.0);

    // Colors
    sling.setBackgroundColor(sling.math.vec4(0.15, 0.15, 0.15, 1.0));
    style.*.Colors[ig.ImGuiCol_Text] = .{ .x = 1.00, .y = 1.00, .z = 1.00, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_TextDisabled] = .{ .x = 0.50, .y = 0.50, .z = 0.50, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_WindowBg] = .{ .x = 0.14, .y = 0.14, .z = 0.14, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_ChildBg] = .{ .x = 0.15, .y = 0.15, .z = 0.15, .w = 0.00 };
    style.*.Colors[ig.ImGuiCol_PopupBg] = .{ .x = 0.08, .y = 0.08, .z = 0.08, .w = 0.94 };
    style.*.Colors[ig.ImGuiCol_Border] = .{ .x = 0.02, .y = 0.02, .z = 0.02, .w = 0.50 };
    style.*.Colors[ig.ImGuiCol_BorderShadow] = .{ .x = 0.00, .y = 0.00, .z = 0.00, .w = 0.00 };
    style.*.Colors[ig.ImGuiCol_FrameBg] = .{ .x = 0.04, .y = 0.04, .z = 0.04, .w = 0.63 };
    style.*.Colors[ig.ImGuiCol_FrameBgHovered] = .{ .x = 0.27, .y = 0.27, .z = 0.27, .w = 0.40 };
    style.*.Colors[ig.ImGuiCol_FrameBgActive] = .{ .x = 0.10, .y = 0.10, .z = 0.10, .w = 0.67 };
    style.*.Colors[ig.ImGuiCol_TitleBg] = .{ .x = 0.09, .y = 0.09, .z = 0.09, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_TitleBgActive] = .{ .x = 0.10, .y = 0.10, .z = 0.10, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_TitleBgCollapsed] = .{ .x = 0.00, .y = 0.00, .z = 0.00, .w = 0.51 };
    style.*.Colors[ig.ImGuiCol_MenuBarBg] = .{ .x = 0.14, .y = 0.14, .z = 0.14, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_ScrollbarBg] = .{ .x = 0.02, .y = 0.02, .z = 0.02, .w = 0.13 };
    style.*.Colors[ig.ImGuiCol_ScrollbarGrab] = .{ .x = 0.31, .y = 0.31, .z = 0.31, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_ScrollbarGrabHovered] = .{ .x = 0.41, .y = 0.41, .z = 0.41, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_ScrollbarGrabActive] = .{ .x = 0.51, .y = 0.51, .z = 0.51, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_CheckMark] = .{ .x = 0.95, .y = 0.95, .z = 0.95, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_SliderGrab] = .{ .x = 0.43, .y = 0.43, .z = 0.43, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_SliderGrabActive] = .{ .x = 0.53, .y = 0.53, .z = 0.53, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_Button] = .{ .x = 0.45, .y = 0.45, .z = 0.45, .w = 0.40 };
    style.*.Colors[ig.ImGuiCol_ButtonHovered] = .{ .x = 0.71, .y = 0.57, .z = 0.22, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_ButtonActive] = .{ .x = 0.99, .y = 0.77, .z = 0.22, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_Header] = .{ .x = 0.47, .y = 0.47, .z = 0.47, .w = 0.31 };
    style.*.Colors[ig.ImGuiCol_HeaderHovered] = .{ .x = 0.96, .y = 0.83, .z = 0.29, .w = 0.40 };
    style.*.Colors[ig.ImGuiCol_HeaderActive] = .{ .x = 1.00, .y = 0.82, .z = 0.12, .w = 0.47 };
    style.*.Colors[ig.ImGuiCol_Separator] = .{ .x = 0.43, .y = 0.43, .z = 0.50, .w = 0.50 };
    style.*.Colors[ig.ImGuiCol_SeparatorHovered] = .{ .x = 0.87, .y = 0.60, .z = 0.19, .w = 0.86 };
    style.*.Colors[ig.ImGuiCol_SeparatorActive] = .{ .x = 0.97, .y = 1.00, .z = 0.00, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_ResizeGrip] = .{ .x = 0.96, .y = 0.83, .z = 0.29, .w = 0.40 };
    style.*.Colors[ig.ImGuiCol_ResizeGripHovered] = .{ .x = 0.71, .y = 0.57, .z = 0.22, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_ResizeGripActive] = .{ .x = 0.99, .y = 0.77, .z = 0.22, .w = 0.63 };
    style.*.Colors[ig.ImGuiCol_Tab] = .{ .x = 0.89, .y = 0.78, .z = 0.37, .w = 0.00 };
    style.*.Colors[ig.ImGuiCol_TabHovered] = .{ .x = 0.71, .y = 0.57, .z = 0.22, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_TabActive] = .{ .x = 0.99, .y = 0.77, .z = 0.22, .w = 0.63 };
    style.*.Colors[ig.ImGuiCol_TabUnfocused] = .{ .x = 0.45, .y = 0.45, .z = 0.45, .w = 0.40 };
    style.*.Colors[ig.ImGuiCol_TabUnfocusedActive] = .{ .x = 0.45, .y = 0.45, .z = 0.45, .w = 0.40 };
    style.*.Colors[ig.ImGuiCol_DockingPreview] = .{ .x = 1.00, .y = 1.00, .z = 1.00, .w = 0.70 };
    style.*.Colors[ig.ImGuiCol_PlotLines] = .{ .x = 0.61, .y = 0.61, .z = 0.61, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_PlotLinesHovered] = .{ .x = 1.00, .y = 0.43, .z = 0.35, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_PlotHistogram] = .{ .x = 0.90, .y = 0.70, .z = 0.00, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_PlotHistogramHovered] = .{ .x = 1.00, .y = 0.60, .z = 0.00, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_TableHeaderBg] = .{ .x = 0.19, .y = 0.19, .z = 0.20, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_TableBorderStrong] = .{ .x = 0.31, .y = 0.31, .z = 0.35, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_TableBorderLight] = .{ .x = 0.23, .y = 0.23, .z = 0.25, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_TableRowBg] = .{ .x = 0.00, .y = 0.00, .z = 0.00, .w = 0.00 };
    style.*.Colors[ig.ImGuiCol_TableRowBgAlt] = .{ .x = 1.00, .y = 1.00, .z = 1.00, .w = 0.06 };
    style.*.Colors[ig.ImGuiCol_TextSelectedBg] = .{ .x = 0.26, .y = 0.59, .z = 0.98, .w = 0.35 };
    style.*.Colors[ig.ImGuiCol_DragDropTarget] = .{ .x = 1.00, .y = 1.00, .z = 0.00, .w = 0.90 };
    style.*.Colors[ig.ImGuiCol_NavHighlight] = .{ .x = 1.00, .y = 0.68, .z = 0.37, .w = 1.00 };
    style.*.Colors[ig.ImGuiCol_NavWindowingHighlight] = .{ .x = 1.00, .y = 1.00, .z = 1.00, .w = 0.70 };
    style.*.Colors[ig.ImGuiCol_NavWindowingDimBg] = .{ .x = 0.80, .y = 0.80, .z = 0.80, .w = 0.20 };
    style.*.Colors[ig.ImGuiCol_ModalWindowDimBg] = .{ .x = 0.04, .y = 0.04, .z = 0.04, .w = 0.76 };
    // Borders
    style.*.TabBorderSize = 0.0;
    style.*.ChildBorderSize = 0.0;
    style.*.FrameBorderSize = 0.0;
    style.*.WindowBorderSize = 1.0;
    // Scrollbar
    style.*.ScrollbarRounding = 0.0;
    style.*.ScrollbarSize = 7.0;
}
