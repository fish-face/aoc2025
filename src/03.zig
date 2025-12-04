const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;

/// argMax which searches a many-item pointer to be certain we do no unnecessary bounds checking
pub fn findMax(comptime T: type, slice: [*]const T, len: usize) usize {
    var best = slice[0];
    var index: usize = 0;
    for (0..len-1) |i| {
        const item = slice[i+1];
        if (item > best) {
            best = item;
            index = i + 1;
        }
    }
    return index;
}

fn part1(line: []const u8) u64 {
    const l = line.len;
    const maxi = std.mem.indexOfMax(u8, line[0 .. l - 1]);
    const a = line[maxi];
    const b = std.mem.max(u8, line[maxi + 1 ..]);

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

        const search = line[m..];
        m += findMax(u8, search.ptr, r - m);
        acc *= 10;
        acc += line[m] - '0';
        m += 1;
    }

    return acc;
}

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);
    for (0..100) |i| {
        var lines = try reader.iterLines();
        var p1: u64 = 0;
        var p2: u64 = 0;
        while (lines.next()) |line| {
            p1 += part1(line);
            p2 += part2(line);
        }
        if (i == 99) {
            try aoc.print("{d}\n{d}\n", .{ p1, p2 });
        }
    }
}

test "findMax" {
    {
        const data = "123454321";
        const i = findMax(u8, data.ptr, 9);
        try std.testing.expectEqual(i, 4);
    }
    {
        const data = "8123454321";
        const i = findMax(u8, data.ptr, 10);
        try std.testing.expectEqual(i, 0);
    }
    {
        const data = "3442444213";
        const i = findMax(u8, data.ptr, 10);
        try std.testing.expectEqual(i, 1);
    }
}