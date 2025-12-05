const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;
const pow = std.math.pow;
const Set = std.AutoHashMap(usize, void);

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
    &.{},
    // 3
    &.{111},
    // 4
    &.{},
    // 5
    &.{11111},
    // 6
    &.{10101},
    // 7
    &.{1111111},
    // 8
    &.{},
    // 9
    &.{1001001},
    // 10
    &.{101010101},
    // 11
    &.{11111111111},
};

fn step(range: []const u8) Ctxt {
    const len_lower = std.mem.findScalar(u8, range, '-') orelse unreachable;
    // TODO opti: we are eating an extra 2x tests per digit here to ignore invalid digits when we could
    //      more cheaply check the last char (as that's where a newline can sneak in) or otherwise
    //      ensure a newline there is stripped.
    const l = aoc.parse.atoi_stripped(usize, range[0..len_lower]);
    const u = aoc.parse.atoi_stripped(usize, range[len_lower + 1 ..]);

    var part1: usize = 0;
    var part2: usize = 0;

    // std.log.debug("range {s}:", .{range});
    // GRIPE for loop can't iterate inclusive ranges

    // Strategy
    // For each range we break the problem down into the different numbers of digits that occur within the range.
    // e.g. for 95-115, we cover numbers with 2 and 3 digits.
    // For each digit number, we have an array (above) of divisors. Any number with that number of digits which is
    // divisible by that divisor displays a repeated pattern. E.g. 10101 * 12 = 121212.
    // First though, if the number of digits is even, we need to separately do part1. In this case the test divisor
    // has the form 101, 1001, 10001, ... etc, e.g. 1001 * 123 = 123123. We add the result of this test to the part1
    // and part2 counts (how this is calculated is explained below)
    // Now we test the other divisors. These are prefiltered so e.g. for 6 digits, we don't include 111111, as 1001
    // divides 111111 so we have already accounted for this in part1.
    // The final step is that for 6 and 10 there are still divisors which cover more than one pattern. These are handled
    // by subtracting the counts for the lowest common multiples of those divisors. Since there are only two such cases,
    // they are special cased.
    for (digits(l)..digits(u) + 1) |n_digits| {
        const min = pow(usize, 10, n_digits - 1);
        const max = pow(usize, 10, n_digits);
        const tds = test_divisors[n_digits];
        // std.log.debug("  {d}=[{d}, {d}] {any}", .{n_digits, min, max, tds});
        if (n_digits % 2 == 0) {
            const div = pow(usize, 10, n_digits / 2) + 1;
            const invalid = sumMultiples(div, @max(l, min), @min(u, max));
            part1 += invalid;
            part2 += invalid;
        }
        for (tds) |div| {
            part2 += sumMultiples(div, @max(l, min), @min(u, max));
            if (n_digits == 6) {
                // std.log.debug("  minus", .{});
                part2 -= sumMultiples(111111, @max(l, min), @min(u, max));
            }
            if (n_digits == 10) {
                // std.log.debug("  minus", .{});
                part2 -= sumMultiples(1111111111, @max(l, min), @min(u, max));
            }
        }
    }
    return .{ .part1 = part1, .part2 = part2 };
}

/// Sum the numbers divisible by divisor within the inclusive range
fn sumMultiples(divisor: usize, l: usize, u: usize) usize {
    // advance i to next multiple of divisor if it is not already a multiple
    const first = l + divisor - ((l - 1) % divisor) - 1;
    if (first > u) {
        return 0;
    }
    // arithmetic series
    const N = (u - first) / divisor + 1;
    return @divTrunc(N * (first + first + (N - 1) * divisor), 2);
}

// GRIPE: I can't add literal values in control-flow because they are "comptime_int" and for some reason don't get coerced to the actual type, and this is an error??
// GRIPE: can't iterate signed ranges with for lol
// GRIPE: WHY THE FUCK CAN'T I FORMAT & PRINT BOOLEAN VALUES, NOR CAST THEM TO AN INTEGER IN A PRINT?
// GRIPE: you need this to test that end > start, rather than just getting a loop that never executes its body, and the error if you don't is "integer overflow". Bug has been open for 3 years.

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);
    var part1: usize = 0;
    var part2: usize = 0;

    var ranges = try reader.iterDelim(',');
    while (ranges.next()) |range| {
        const item = step(range);
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
