const std = @import("std");

pub fn Pt(comptime T: type) type {
    return struct {
        const Self = @This();
        x: T,
        y: T,

        // GRIPE: operator overloading haters can boil their heads in vats of acid
        pub fn add(a: Self, b: Self) Self {
            return .{ .x = a.x + b.x, .y = a.y + b.y };
        }

        pub fn sub(a: Self, b: Self) Self {
            return .{ .x = a.x - b.x, .y = a.y - b.y };
        }

        pub fn neighbours4in(p: Self, width: T, height: T) [4]?Self {
            return [_]?Self{
                if (p.x > 0) .{ .x = p.x - 1, .y = p.y } else null,
                if (p.y > 0) .{ .x = p.x, .y = p.y - 1 } else null,
                if (p.x < width - 1) .{ .x = p.x + 1, .y = p.y } else null,
                if (p.y < height - 1) .{ .x = p.x, .y = p.y + 1 } else null,
            };
        }
        pub fn neighbours4(p: Self) [4]?Self {
            return [_]?Self{
                if (p.x > 0) .{ .x = p.x - 1, .y = p.y } else null,
                if (p.y > 0) .{ .x = p.x, .y = p.y - 1 } else null,
                .{ .x = p.x + 1, .y = p.y },
                .{ .x = p.x, .y = p.y + 1 },
            };
        }

        pub fn neighbours8in(p: Self, width: T, height: T) [8]?Self {
            return [_]?Self{
                if (p.x > 0)
                    .{ .x = p.x - 1, .y = p.y }
                else null,
                if (p.y > 0)
                    .{ .x = p.x, .y = p.y - 1 }
                else null,
                if (p.x < width - 1)
                    .{ .x = p.x + 1, .y = p.y }
                else null,
                if (p.y < height - 1)
                    .{ .x = p.x, .y = p.y + 1 }
                else null,
                if (p.x > 0 and p.y > 0)
                    .{ .x = p.x - 1, .y = p.y - 1 }
                else null,
                if (p.x > 0 and p.y < height - 1)
                    .{ .x = p.x - 1, .y = p.y + 1 }
                else null,
                if (p.x < width - 1 and p.y > 0)
                    .{ .x = p.x + 1, .y = p.y - 1 }
                else null,
                if (p.x < width - 1 and p.y < height - 1)
                    .{ .x = p.x + 1, .y = p.y + 1 }
                else null,
            };
        }

        pub fn format(
            self: Self,
            writer: *std.Io.Writer,
        ) std.Io.Writer.Error!void {
            try writer.print("({any} {any})", .{self.x, self.y});
        }
    };
}
