const std = @import("std");
const debug = std.debug;
const fmt = std.fmt;
const rl = @import("raylib.zig");
const rm = @import("raymath.zig");
const screen_settings = @import("screen_settings.zig");
const color_picker = @import("color_picker.zig");

// helpers imports
const helpers = @import("helpers.zig");
const string = helpers.string;
const string_view = helpers.string_view;
const arrToVec = helpers.arrToVec;
const oom = helpers.oom;

var fmt_vec_buf: [128]u8 = undefined;

inline fn fmtVec(vec: rl.Vector2) string_view {
    return fmt.bufPrint(&fmt_vec_buf, "[{d}, {d}]", .{ vec.x, vec.y }) catch unreachable;
}

fn drawInfo(camera: *const rl.Camera2D) void {
    var buf: [1024]u8 = undefined;
    rl.DrawRectangle(0, 0, 300, 200, rl.ColorAlpha(rl.GRAY, 0.3));
    var pos_x: i32 = 10;
    var pos_y: i32 = 10;

    var str = fmt.bufPrintZ(&buf, "Zoom: {d}", .{camera.zoom}) catch unreachable;
    rl.DrawText(str.ptr, pos_x, pos_y, 20, rl.BLACK);
    pos_y += 30;

    str = fmt.bufPrintZ(&buf, "Mouse Pos: {s}", .{fmtVec(rl.GetMousePosition())}) catch unreachable;
    rl.DrawText(str, pos_x, pos_y, 20, rl.BLACK);
    pos_y += 30;

    str = fmt.bufPrintZ(&buf, "Mouse Pos World: {s}", .{fmtVec(rlMousePosInWorld(camera.*))}) catch unreachable;
    rl.DrawText(str, pos_x, pos_y, 20, rl.BLACK);
    pos_y += 30;

    // str = fmt.bufPrintZ(&buf, "Mouse Delta: {s}", .{fmtVec(rl.GetMouseDelta())}) catch unreachable;
    // rl.DrawText(str, pos_x, pos_y, 20, rl.BLACK);
    // pos_y += 30;
}

inline fn rlMousePosInWorld(camera: rl.Camera2D) rl.Vector2 {
    return rl.GetScreenToWorld2D(rl.GetMousePosition(), camera);
}

const RectState = struct {
    rect: rl.Rectangle,
    color: rl.Color,
    text: std.ArrayList(u8),
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    debug.assert(!gpa.detectLeaks());
    var allocator = gpa.allocator();

    var active_rect_index: ?usize = null;

    var rects = std.ArrayList(RectState).initCapacity(allocator, 100) catch oom();
    defer {
        for (rects.items) |rect| {
            rect.text.deinit();
        }
        rects.deinit();
    }

    color_picker.init(allocator);
    defer color_picker.deinit();

    var draw_text_buf: [1024]u8 = undefined;

    rl.SetTraceLogLevel(rl.LOG_WARNING);
    rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT);
    rl.InitWindow(screen_settings.width, screen_settings.height, "raylib [core] example - basic window");
    rl.SetTargetFPS(120);

    var start_pos: rl.Vector2 = undefined;
    var camera = rl.Camera2D{
        .offset = arrToVec(.{ screen_settings.width / 2, screen_settings.height / 2 }),
        .target = arrToVec(.{ 0.0, 0.0 }),
        .rotation = 0.0,
        .zoom = 0.5,
    };

    var moving_camera = false;

    while (!rl.WindowShouldClose()) {
        if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
            start_pos = rlMousePosInWorld(camera);
        } else if (rl.IsMouseButtonReleased(rl.MOUSE_BUTTON_LEFT)) {
            var end_pos = rlMousePosInWorld(camera);
            var diff = rm.Vector2Subtract(end_pos, start_pos);
            var rect_pos = arrToVec(.{
                if (start_pos.x < end_pos.x) start_pos.x else end_pos.x,
                if (start_pos.y < end_pos.y) start_pos.y else end_pos.y,
            });
            var rect_to_draw = rl.Rectangle{
                .x = rect_pos.x,
                .y = rect_pos.y,
                .width = @abs(diff.x),
                .height = @abs(diff.y),
            };

            rects.append(.{
                .rect = rect_to_draw,
                .color = color_picker.getActiveColor(),
                .text = std.ArrayList(u8).init(allocator),
            }) catch oom();

            active_rect_index = if (active_rect_index) |v| v + 1 else 0;
        }

        // _____________Zoom_______________________
        var zoom_step = rl.GetMouseWheelMove() * 0.02;
        if (zoom_step != 0) {
            camera.zoom += zoom_step;
            if (camera.zoom < 0.03) {
                camera.zoom = 0.03;
            } else if (camera.zoom > 1.0) {
                camera.zoom = 1.0;
            }
        }
        //_____________________________________________

        if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_RIGHT)) {
            moving_camera = true;
            rl.HideCursor();
        } else if (rl.IsMouseButtonReleased(rl.MOUSE_BUTTON_RIGHT)) {
            moving_camera = false;
            rl.ShowCursor();
        }

        if (rl.IsKeyPressed(rl.KEY_F11)) {
            rl.ToggleBorderlessWindowed();
        } else if (rl.IsKeyPressed(rl.KEY_R)) {
            camera.target = rm.Vector2Zero();
        }

        if (active_rect_index) |rect_index| {
            var c = rl.GetCharPressed();
            var rect_text = &rects.items[rect_index].text;
            if (c != 0) {
                rect_text.append(@intCast(c)) catch oom();
                if (rect_text.items.len % 20 == 0) {
                    rect_text.append('\n') catch oom();
                }
            }
            if (rl.IsKeyPressed(rl.KEY_BACKSPACE)) {
                if (rect_text.items.len > 0) {
                    rect_text.items.len -= 1;
                }
            }
        }

        if (moving_camera) {
            var delta = rm.Vector2Divide(rl.GetMouseDelta(), arrToVec(.{ camera.zoom, camera.zoom }));
            camera.target = rm.Vector2Add(camera.target, delta);
        }

        color_picker.update();

        // ------------------------------- DRAW -------------------------------
        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);
        rl.DrawFPS(screen_settings.width / 2, 10);

        rl.BeginMode2D(camera);

        for (rects.items) |iter| {
            rl.DrawRectangleRounded(iter.rect, 0.1, 0, rl.Fade(iter.color, 0.4));
            if (iter.text.items.len > 0) {
                var text = fmt.bufPrintZ(&draw_text_buf, "{s}", .{iter.text.items}) catch oom();
                var text_half: f32 = @as(f32, @floatFromInt(rl.MeasureText(text, 40))) / 2;
                const text_x: i32 = @intFromFloat(iter.rect.x + iter.rect.width / 2 - text_half);
                const text_y: i32 = @intFromFloat(iter.rect.y + iter.rect.height / 2);
                rl.DrawText(text, text_x, text_y, 40, rl.BLACK);
            }
        }

        rl.EndMode2D();

        drawInfo(&camera);
        color_picker.draw();

        rl.EndDrawing();
    }

    rl.CloseWindow();
}

test {
    std.testing.refAllDecls(@This());
}
