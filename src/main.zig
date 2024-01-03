const std = @import("std");
const rl = @import("raylib.zig");

pub fn main() !void {
    rl.InitWindow(1280, 800, "raylib [core] example - basic window");
    rl.SetTargetFPS(60);

    while (!rl.WindowShouldClose()) // Detect window close button or ESC key
    {
        // Input
        //----------------------------------------------------------------------------------

        // Update
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);
        rl.DrawText("Congrats! You created your first window!", 190, 200, 20, rl.LIGHTGRAY);
        rl.EndDrawing();
    }

    rl.CloseWindow();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
