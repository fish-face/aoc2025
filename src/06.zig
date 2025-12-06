const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);

    var p1: usize = 0;
    var p2: usize = 0;

    for (0..1) |_| {
        var lines = try reader.iterLines();
        var cols = [_][4]u16{[_]u16{undefined} ** 4} ** 1024;
        var ops = [_]u8{undefined} ** 1024;

        var l: usize = 0;
        var c: usize = 0;

        while (lines.next()) |line| {
            c = 0;
            var entries = std.mem.tokenizeScalar(u8, line, ' ');
            while (entries.next()) |entry| {
                if (entry[0] == '+' or entry[0] == '*') {
                    ops[c] = entry[0];
                } else {
                    cols[c][l] = aoc.parse.atoi_stripped(u16, entry);
                }
                c += 1;
            }
            l += 1;
        }

        // std.log.debug("{any}", .{ops});

        // NOTE swap to work on arbitrary numbers of lines (e.g. sample)
        // const num_lines = l - 1;
        const num_lines: usize = 4;
        const num_cols = c;
        var acc: u64 = 0;

        // TODO opti can do at the same time as parsing if we keep two accumulators
        for (cols[0..num_cols], 0..) |col, cc| {
            const op = ops[cc];
            acc = if (op == '+') 0 else 1;
            for (col[0..num_lines]) |num| {
                if (op == '+') {
                    acc += num;
                } else {
                    acc *= num;
                }
            }
            // std.log.debug("{d}", .{acc});
            p1 += acc;
        }

        const input = try reader.mmap();
        // TODO opti?
        const line_len = std.mem.findScalar(u8, input, '\n').? + 1;
        // var cols = [_][4]u16{ [_]u16{undefined} ** 4} ** 4096;

        var block_acc: u64 = undefined;
        var op: u8 = 0;
        for (0..line_len - 1) |i| {
            var num_acc: u64 = 0;

            for (0..num_lines) |ll| {
                const digit = input[i + ll * line_len];
                // std.log.debug("{d},{d}='{c}'", .{i, ll, digit});
                if (digit == ' ') continue;
                num_acc *= 10;
                num_acc += digit - '0';
            }
            const maybe_op = input[i + num_lines * line_len];
            // std.log.debug("op? {d},{d}='{c}'", .{i, num_lines, maybe_op});
            if (maybe_op != ' ') {
                op = maybe_op;
                block_acc = num_acc;
                // std.log.debug("setting op to {c}", .{op});
            } else if (num_acc == 0) {
                // number in column is zero, and no op: this is a blank column. Accumulate to part2 total.
                p2 += block_acc;
                op = 0;
                // std.log.debug("adding {d} for {c} block {d}", .{ block_acc, op, i });
            } else {
                if (op == '+') {
                    block_acc += num_acc;
                } else if (op == '*') {
                    block_acc *= num_acc;
                }
                // std.log.debug("applying op {c} to {d}-->{d}", .{op, num_acc, block_acc});
            }
        }
        p2 += block_acc;
    }

    try aoc.print("{d}\n{d}\n", .{ p1, p2 });
}
