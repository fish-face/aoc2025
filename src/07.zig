const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;

fn log_state_pair(left: u128, right: u128) void {
    std.log.debug("{b:0>128}|{b:0>128}", .{left, right});
}

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);

    var p1: usize = 0;
    var p2: usize = 0;

    for (0..aoc.build_options.repeats) |repeat| {
        var lines = try reader.iterLines();
        
        var state_l: u128 = undefined;
        var state_r: u128 = undefined;
        if (aoc.build_options.sample_mode) {
            state_l = 1 << 7;
            state_r = 0;
        } else {
            state_r = 0;
            state_l = 1 << (128 - 70) - 1;
        }
        
        while (lines.next()) |line| {
            var bin_line_l: u128 = 0;
            var bin_line_r: u128 = 0;
            if (aoc.build_options.sample_mode) {
                for (line[0..15]) |c| {
                    if (c != '\n') bin_line_l <<= 1;
                    if (c == '^') bin_line_l += 1;
                }
            } else {
                for (line[0..128]) |c| {
                    if (c != '\n') bin_line_l <<= 1;
                    if (c == '^') bin_line_l += 1;
                }
                for (line[128..]) |c| {
                    if (c != '\n') bin_line_r <<= 1;
                    if (c == '^') bin_line_r += 1;
                }
                bin_line_r <<= 128 - (141 - 128);
            }
            // log_state_pair(state_l, state_r);
            // log_state_pair(bin_line_l, bin_line_r);
            // std.log.debug("s: {b}", .{state});
            // std.log.debug("l: {b}", .{bin_line});
            const active_splitters_l = state_l & bin_line_l;
            const active_splitters_r = state_r & bin_line_r;
            // std.log.debug("m: {b}", .{active_splitters});
            p1 += @popCount(active_splitters_l) + @popCount(active_splitters_r);
            const left_split_l = active_splitters_l << 1;
            const left_split_r = active_splitters_r << 1;
            const right_split_l = active_splitters_l >> 1;
            const right_split_r = active_splitters_r >> 1;
            const edge_l = @as(u128, if (active_splitters_r & (1 << 127) > 0) 1 else 0);
            const edge_r = @as(u128, if (active_splitters_l & (1) > 0) (1 << 127) else 0);
            state_l = state_l | left_split_l | right_split_l | edge_l & ~active_splitters_l;
            state_r = state_r | left_split_r | right_split_r | edge_r & ~active_splitters_r;
            // log_state_pair(bin_line_l, bin_line_r);
            log_state_pair(state_l, state_r);

            // skip known blank lines
            _ = lines.next();
        }
        // state += 1;

        p1 += 0;
        p2 += 0;

        if (repeat == 0) {
            try aoc.print("{d}\n{d}\n", .{p1, p2});
        }
    }
}