const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;

fn part1(line: []const u8) u64 {
    const l = line.len;
    const maxi = std.mem.indexOfMax(u8, line[0..l-1]);
    const a = line[maxi];
    const b = std.mem.max(u8, line[maxi+1..]);

    const joltage: u64 = 10 * (a - '0') + (b - '0');

    return joltage;
}

fn part2(line: []const u8) u64 {
    const l = line.len;
    var m: usize = 0;
    var acc: u64 = 0;
    for (0..12) |i| {
        const r_off = 12 - i - 1;
        const r = l - r_off;

        const search = line[m..r];
        m += std.mem.indexOfMax(u8, search);
        acc *= 10;
        acc += line[m] - '0';
        m += 1;
    }

    return acc;
}

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);
    var lines = try reader.iterLines();
    var p1: u64 = 0;
    var p2: u64 = 0;
    while (lines.next()) |line| {
        p1 += part1(line);
        p2 += part2(line);
    }
    try aoc.print("{d}\n{d}\n", .{p1, p2});
}

