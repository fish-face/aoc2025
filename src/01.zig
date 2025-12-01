const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;

const Instruction = struct {
    n: i16,

    fn from_str(_: Allocator, s: []const u8) !Instruction {
        const dir: i8 = switch (s[0]) {
            'L' => -1,
            'R' => 1,
            else => return error.ParseError,
        };
        return .{
            .n = dir * (try std.fmt.parseInt(i16, s[1..], 10)),
        };
    }

    fn apply(self: Instruction, n: i16) struct {i16, u16} {
        const val = n + self.n;

        // GRIPE: there being different standards in different languages is not a good reason to avoid picking a standard, and forcing everyone to use ugly function names
        var overflow = @abs(@divFloor(val, 100));

        // Horrible horrible edge cases
        if (n == 0 and val < 0) {
            overflow -= 1;
        }
        if (val <= 0 and @mod(val, 100) == 0) {
            overflow += 1;
        }
        return .{
            @mod(val, 100),
            overflow,
        };
    }

    pub fn format(
        self: Instruction,
        writer: *std.Io.Writer,
    ) !void {
        try writer.print("{f} {d}", .{self.dir, self.n});
    }
};

pub fn main() !void {
    const allocator = try aoc.allocator();
    const reader = try aoc.Reader.init(allocator);
    const input = try reader.parseLines(Instruction, Instruction.from_str);
    var n: i16 = 50;
    var part1: u16 = 0;
    var part2: u16 = 0;
    for (input.items) |line| {
        n, const overflow = line.apply(n);
        if (n == 0) {
            part1 += 1;
        }
        part2 += overflow;
    }

    try aoc.print("{d}\n", .{part1});
    try aoc.print("{d}\n", .{part2});
}

test "test instruction application" {
    const allocator = try aoc.allocator();
    try std.testing.expectEqual(
        (try Instruction.from_str(allocator, "R1")).apply(0),
        .{1, 0}
    );
    try std.testing.expectEqual(
        (try Instruction.from_str(allocator, "R1")).apply(99),
        .{0, 1}
    );
    try std.testing.expectEqual(
        (try Instruction.from_str(allocator, "L1")).apply(0),
        .{99, 0}
    );
    try std.testing.expectEqual(
        (try Instruction.from_str(allocator, "L1")).apply(99),
        .{98, 0}
    );
    try std.testing.expectEqual(
        (try Instruction.from_str(allocator, "L100")).apply(0),
        .{0, 1}
    );
    try std.testing.expectEqual(
        (try Instruction.from_str(allocator, "L100")).apply(1),
        .{1, 1}
    );
    try std.testing.expectEqual(
        (try Instruction.from_str(allocator, "R100")).apply(0),
        .{0, 1}
    );
    try std.testing.expectEqual(
        (try Instruction.from_str(allocator, "R100")).apply(1),
        .{1, 1}
    );

    try std.testing.expectEqual(
        (try Instruction.from_str(allocator, "L200")).apply(0),
        .{0, 2}
    );
    try std.testing.expectEqual(
        (try Instruction.from_str(allocator, "L199")).apply(99),
        .{0, 2}
    );
    try std.testing.expectEqual(
        (try Instruction.from_str(allocator, "R200")).apply(1),
        .{1, 2}
    );
    try std.testing.expectEqual(
        (try Instruction.from_str(allocator, "R199")).apply(1),
        .{0, 2}
    );
}