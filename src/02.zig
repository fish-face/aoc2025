const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;
const pow = std.math.pow;

fn step(_: Allocator, range: []const u8, count: i64) i64 {
    const len_lower = std.mem.findScalar(u8, range, '-') orelse unreachable;
    const len_upper = range.len - len_lower - 1;
    const l = range[0..len_lower];
    const u = range[len_lower+1..];
    const half_lower = len_lower / 2;
    const half_upper = len_upper / 2;

    const ll, const lu = if (half_lower == 0)
        .{0, 0}
    else
        .{
            std.fmt.parseInt(i64, l[0..half_lower], 10) catch unreachable,
            std.fmt.parseInt(i64, l[half_lower..], 10) catch unreachable
        };
    const ul = std.fmt.parseInt(i64, u[0..half_upper], 10) catch unreachable;
    const uu = std.fmt.parseInt(i64, u[half_upper..], 10) catch unreachable;

    var invalid: i64 = 0;

    if (len_lower % 2 == 0) {
        if (len_upper == len_lower) {
            invalid = processRange(@intCast(half_lower), ll, lu, ul, uu);
        } else {
            invalid = processRange(@intCast(half_lower), ll, lu, pow(i64, 10, @intCast(half_lower)) - 1, pow(i64, 10, @intCast(half_lower)) - 1);
        }
    }

    if (len_upper % 2 == 0) {
        if (len_upper > len_lower) {
            invalid += processRange(@intCast(half_upper), pow(i64, 10, (@intCast(half_lower))), 0, ul, uu);
        }
    }

    if (half_upper > half_lower + 1) {
        // GRIPE: you need this if statement, rather than just getting a loop that never executes its body, and the error if you don't is "integer overflow". Bug has been open for 3 years.
        for (half_lower + 1 .. half_upper) |i| {
            if (i % 2 == 1) continue;

            const val = pow(i64, 10, @intCast(i));
            invalid += val;
        }
    }

    return count + invalid;
}

fn processRange(digits: i64, ll: i64, lu: i64, ul: i64, uu: i64) i64 {
    // GRIPE: I can't add literal values in control-flow because they are "comptime_int" and for some reason don't get coerced to the actual type, and this is an error??
    const first = if (ll >= lu) ll else ll+1;
    const last = if (ul <= uu) ul else ul-1;
    const repeater = pow(i64, 10, digits) + 1;

    if (first > last) return 0;

    // arithmetic series
    const N = last - first + 1;
    return @divTrunc(N * repeater * (first + last), 2);
    // GRIPE: can't iterate signed ranges with for lol
    // GRIPE: WHY THE FUCK CAN'T I FORMAT & PRINT BOOLEAN VALUES, NOR CAST THEM TO AN INTEGER IN A PRINT?
}

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);
    const res = try reader.foldDelim(',', i64, 0, step);
    try aoc.print("{d}\n", .{res});
}

