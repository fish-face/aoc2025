const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);

    var p1: usize = 0;
    var p2: usize = 0;

    for (0..aoc.build_options.repeats) |repeat| {
        var lines = try reader.iterLines();

        var state = [_]u64{0} ** 141;
        if (aoc.build_options.sample_mode) {
            state[7] = 1;
        } else {
            state[70] = 1;
        }

        while (lines.next()) |line| {
            for (line, 0..) |c, i| {
                if (c == '^' and state[i] > 0) {
                    state[i-1] += state[i];
                    state[i+1] += state[i];
                    state[i] = 0;
                    p1 += 1;
                }
            }
            // skip known blank lines
            _ = lines.next();
        }
        for (state) |n| {
            p2 += n;
        }

        if (repeat == 0) {
            try aoc.print("{d}\n{d}\n", .{p1, p2});
        }
    }
}