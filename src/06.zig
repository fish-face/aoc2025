const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);

    var p1: usize = 0;
    var p2: usize = 0;

    for (0..aoc.build_options.repeats) |_| {
        const num_lines: usize = 4;

        const input = try reader.mmap();
        // TODO opti?
        const line_len = std.mem.findScalar(u8, input, '\n').? + 1;
        // var cols = [_][4]u16{ [_]u16{undefined} ** 4} ** 4096;

        // accumulator for the part2 value of the block
        var block_acc: u64 = undefined;
        var op: u8 = 0;
        var col_acc = [_]u64{0} ** 4;
        for (0..line_len - 1) |i| {
            // accumulator for the vertical number
            var num_acc: u64 = 0;
            // 1 accumulator for each horizontal number

            for (0..num_lines) |ll| {
                const digit = input[i + ll * line_len];
                // std.log.debug("{d},{d}='{c}'", .{i, ll, digit});
                if (digit == ' ') continue;
                col_acc[ll] *= 10;
                col_acc[ll] += digit - '0';
                // std.log.debug("{d},{d}='{c}'-->{d}", .{i, ll, digit, col_acc[ll]});
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
                // number in column is zero, and no op: this is a blank column. Accumulate to part totals.
                if (op == '+') {
                    p1 += col_acc[0] + col_acc[1] + col_acc[2] + col_acc[3];
                    // std.log.debug("adding p1 {d} for {c} block {d}",
                    // .{ col_acc[0] + col_acc[1] + col_acc[2] + col_acc[3], op, i });
                } else {
                    p1 += col_acc[0] * col_acc[1] * col_acc[2] * col_acc[3];
                    // std.log.debug("adding p1 {d} for {c} block {d}",
                    // .{ col_acc[0] * col_acc[1] * col_acc[2] * col_acc[3], op, i });
                }
                p2 += block_acc;
                op = 0;
                col_acc = [_]u64{0} ** 4;
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

        if (op == '+') {
            p1 += col_acc[0] + col_acc[1] + col_acc[2] + col_acc[3];
        } else {
            p1 += col_acc[0] * col_acc[1] * col_acc[2] * col_acc[3];
        }
        p2 += block_acc;
    }

    try aoc.print("{d}\n{d}\n", .{ p1, p2 });
}
