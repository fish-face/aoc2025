const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;
const pow = std.math.pow;

const Ctxt = struct {
    part1: usize,
    part2: usize,
};

fn digits(i: usize) usize {
    return switch (i) {
        0...9 => 1,
        10...99 => 2,
        100...999 => 3,
        1000...9999 => 4,
        10000...99999 => 5,
        100000...999999 => 6,
        1000000...9999999 => 7,
        10000000...99999999 => 8,
        100000000...999999999 => 9,
        1000000000...9999999999 => 10,
        10000000000...99999999999 => 11,
        else => unreachable,
    };
}

const test_divisors: []const []const usize = &.{
    // 0
    &.{},
    // 1
    &.{},
    // 2
    &.{11},
    // 3
    &.{111},
    // 4
    &.{101},
    // 5
    &.{11111},
    // 6
    &.{ 10101, 1001 },
    // 7
    &.{1111111},
    // 8
    &.{10001},
    // 9
    &.{1001001},
    // 10
    &.{ 101010101, 100001 },
    // 11
    &.{11111111111},
};

fn step(range: []const u8) Ctxt {
    const len_lower = std.mem.findScalar(u8, range, '-') orelse unreachable;
    // const len_upper = range.len - len_lower - 1;
    // TODO we are eating an extra 2x tests per digit here to ignore invalid digits when we could
    //      more cheaply check the last char (as that's where a newline can sneak in) or otherwise
    //      ensure a newline there is stripped.
    const l = aoc.parse.atoi_stripped(usize, range[0..len_lower]);
    const u = aoc.parse.atoi_stripped(usize, range[len_lower + 1 ..]);

    var part1: usize = 0;
    var part2: usize = 0;

    // GRIPE for loop can't iterate inclusive ranges
    for (l..u + 1) |i| {
        const invalid1, const invalid2 = testInvalid(digits(i), i);
        if (invalid1) part1 += i;
        if (invalid2) part2 += i;
    }
    // const half_lower = len_lower / 2;
    // const half_upper = len_upper / 2;
    //
    // const ll, const lu = if (half_lower == 0)
    //     .{0, 0}
    // else
    //     .{
    //         std.fmt.parseInt(i64, l[0..half_lower], 10) catch unreachable,
    //         std.fmt.parseInt(i64, l[half_lower..], 10) catch unreachable
    //     };
    // const ul = std.fmt.parseInt(i64, u[0..half_upper], 10) catch unreachable;
    // const uu = std.fmt.parseInt(i64, u[half_upper..], 10) catch unreachable;
    //
    // var invalid: i64 = 0;
    //
    // if (len_lower % 2 == 0) {
    //     if (len_upper == len_lower) {
    //         invalid = processRange(@intCast(half_lower), ll, lu, ul, uu);
    //     } else {
    //         invalid = processRange(@intCast(half_lower), ll, lu, pow(i64, 10, @intCast(half_lower)) - 1, pow(i64, 10, @intCast(half_lower)) - 1);
    //     }
    // }
    //
    // if (len_upper % 2 == 0) {
    //     if (len_upper > len_lower) {
    //         invalid += processRange(@intCast(half_upper), pow(i64, 10, (@intCast(half_lower))), 0, ul, uu);
    //     }
    // }
    //
    // if (half_upper > half_lower + 1) {
    //     // GRIPE: you need this if statement, rather than just getting a loop that never executes its body, and the error if you don't is "integer overflow". Bug has been open for 3 years.
    //     for (half_lower + 1 .. half_upper) |i| {
    //         if (i % 2 == 1) continue;
    //
    //         const val = pow(i64, 10, @intCast(i));
    //         invalid += val;
    //     }
    // }
    //
    return .{ .part1 = part1, .part2 = part2 };
}

fn testInvalid(d: usize, i: usize) struct { bool, bool } {
    if (d % 2 == 0) {
        const p1div = pow(usize, 10, d / 2) + 1;
        if (i % p1div == 0) {
            // std.log.debug("{d} --> {d}: {d}", .{i, p1div, i / p1div});
            return .{ true, true };
        }
    }
    const tds = test_divisors[d];
    for (tds) |div| {
        if (i % div == 0) {
            return .{ false, true };
        }
    }
    return .{ false, false };
}
// fn processRange(digits: i64, ll: i64, lu: i64, ul: i64, uu: i64) Ctxt {
//     // GRIPE: I can't add literal values in control-flow because they are "comptime_int" and for some reason don't get coerced to the actual type, and this is an error??
//     const first = if (ll >= lu) ll else ll+1;
//     const last = if (ul <= uu) ul else ul-1;
//     const repeater = pow(i64, 10, digits) + 1;
//
//     if (first > last) return 0;
//
//     // arithmetic series
//     const N = last - first + 1;
//     return .{@divTrunc(N * repeater * (first + last), 2), 0};
//     // GRIPE: can't iterate signed ranges with for lol
//     // GRIPE: WHY THE FUCK CAN'T I FORMAT & PRINT BOOLEAN VALUES, NOR CAST THEM TO AN INTEGER IN A PRINT?
// }

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);
    // const res = try reader.foldDelim(',', Ctxt, .{ .part1 = 0, .part2 = 0 }, step);
    const invalids = try aoc.parallel_map_unordered(allocator, try reader.iterDelim(','), Ctxt, []const u8, step);
    var part1: usize = 0;
    var part2: usize = 0;

    for (invalids.items) |item| {
        part1 += item.part1;
        part2 += item.part2;
    }
    try aoc.print("{d}\n{d}\n", .{ part1, part2 });
}

test "test divisor creation" {
    for (1..11) |d| {
        const fast_divisors = test_divisors[d];
        var i: usize = 0;
        for (2..d + 1) |p| {
            if (d % p == 0) {
                // GRIPE: type inference incapable of working with int literals
                var testdiv: usize = 0;

                // p is a divisor of the number of digits; construct a test divisor of the number
                // let's hope this gets optimised to divmod lol
                const q = d / p;
                // p = number of 1s, q = distance between 1s
                for (0..p) |j| {
                    testdiv += pow(usize, 10, j * q);
                }
                std.log.warn("{d}: {d} {any}", .{ d, p, fast_divisors });
                try std.testing.expect(i < fast_divisors.len);
                try std.testing.expectEqual(fast_divisors[fast_divisors.len - i - 1], testdiv);
                i += 1;
            }
        }
    }
}
