const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;

const Instruction = struct {
    n: i16,

    fn from_str(s: []const u8) !Instruction {
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

const Ctxt = struct {
    n: i16,
    part1: u16,
    part2: u16,
};

fn step(_: Allocator, line: []const u8, ctxt: Ctxt) Ctxt {
    const instruction = Instruction.from_str(line) catch unreachable;
    var res = ctxt;
    res.n, const overflow = instruction.apply(res.n);
    if (res.n == 0) {
        res.part1 += 1;
    }
    res.part2 += overflow;
    return res;
}

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);
    const ctxt: Ctxt = .{.n = 50, .part1 = 0, .part2 = 0};
    const res = try reader.foldLines(Ctxt, ctxt, step);

    try aoc.print("{d}\n", .{res.part1});
    try aoc.print("{d}\n", .{res.part2});
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