const std = @import("std");
const testing = std.testing;
const debug = std.debug;
const rl = @import("raylib.zig");

pub const string = []u8;
pub const string_view = []const u8;

pub inline fn arrToVec(arr: [2]f32) rl.Vector2 {
    return .{
        .x = arr[0],
        .y = arr[1],
    };
}

pub inline fn oom() noreturn {
    debug.panic("OOM\n", .{});
}

// TODO: now only works for centered (ex. circle)
pub const PosByIndexGenerator = struct {
    const PosByIndexInfo = struct {
        size: f32,
        start: f32 = 0.0,
        gap: ?f32 = null,
    };

    index: usize,
    info: PosByIndexInfo,
    pub fn next(self: *PosByIndexGenerator) f32 {
        const gap = self.info.gap orelse self.info.size / 2;
        const index_f: f32 = @floatFromInt(self.index);
        self.index += 1;
        return self.info.start + index_f * (self.info.size + gap) + self.info.size / 2;
    }

    pub fn init(info: PosByIndexInfo) PosByIndexGenerator {
        return .{
            .info = info,
            .index = 0,
        };
    }
};

test "posByIndex" {
    {
        var iter = PosByIndexGenerator.init(.{ .size = 30, .start = 20 });
        try testing.expectEqual(@as(f32, 35.0), iter.next());
        try testing.expectEqual(@as(f32, 80.0), iter.next());
        try testing.expectEqual(@as(f32, 125.0), iter.next());
    }

    // with gap set
    {
        var iter = PosByIndexGenerator.init(.{ .size = 60, .start = 10, .gap = 40 });
        try testing.expectEqual(@as(f32, 40.0), iter.next());
        try testing.expectEqual(@as(f32, 140.0), iter.next());
    }
}
