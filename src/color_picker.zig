const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib.zig");
const screen_settings = @import("screen_settings.zig");

// helpers imports
const helpers = @import("helpers.zig");
const string = helpers.string;
const string_view = helpers.string_view;
const arrToVec = helpers.arrToVec;
const oom = helpers.oom;
const PosByIndexGenerator = helpers.PosByIndexGenerator;

const ColorWithPos = struct {
    value: rl.Color,
    pos: rl.Vector2,
    index: usize,
};
var active_color_index: usize = 0;
var colors: []ColorWithPos = undefined;
var g_allocator: Allocator = undefined;

const COLOR_RADIUS = 15.0;
const COLOR_X_POS = screen_settings.width - COLOR_RADIUS - 20.0;
const colors_order = [_]rl.Color{ rl.GRAY, rl.RED, rl.GREEN, rl.BLUE };

pub fn init(allocator: Allocator) void {
    g_allocator = allocator;
    colors = allocator.alloc(ColorWithPos, colors_order.len) catch oom();
    var pos_generator = PosByIndexGenerator.init(.{
        .size = COLOR_RADIUS * 2,
        .start = 20,
    });
    for (colors_order, 0..) |color_value, i| {
        colors[i] = .{
            .value = color_value,
            .pos = arrToVec(.{ COLOR_X_POS, pos_generator.next() }),
            .index = i,
        };
    }
}

pub fn deinit() void {
    g_allocator.free(colors);
}

pub fn update() void {
    const mouse_pos = rl.GetMousePosition();
    for (colors) |color| {
        if (rl.CheckCollisionPointCircle(mouse_pos, color.pos, COLOR_RADIUS)) {
            rl.SetMouseCursor(rl.MOUSE_CURSOR_POINTING_HAND);

            if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
                active_color_index = color.index;
            }

            return;
        }
    }
    rl.SetMouseCursor(rl.MOUSE_CURSOR_DEFAULT);
}

pub fn draw() void {
    for (colors) |color| {
        rl.DrawCircleV(color.pos, COLOR_RADIUS, color.value);
        if (active_color_index == color.index) {
            rl.DrawRing(color.pos, COLOR_RADIUS + 2, COLOR_RADIUS + 5, 0, 350, 0, rl.GOLD);
        }
    }
}

pub fn getActiveColor() rl.Color {
    return colors[active_color_index].value;
}
