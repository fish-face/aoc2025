const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;

const Range = struct {
    l: i64, u: i64,
    fn lessThan(_: void, self: Range, other: Range) bool {
        if (self.l < other.l) return true;
        if (self.l == other.l and self.u < other.u) return true;
        return false;
    }

    fn cmpItemL(item: i64, self: Range) std.math.Order {
        return std.math.order(item, self.l);
    }

    fn canBeIn(item: i64, self: Range) bool {
        return item >= self.l;
    }

    // fn cmpItemU(item: i64, self: Range) std.math.Order {
    //     return std.math.order(item, self.u);
    // }

    fn intersect(self: Range, other: Range) ?Range {
        // Returning null rather than empty range allows easier testing of emptiness
        if (self.l > other.u or other.l > self.u) return null;
        return .{
            .l = @max(self.l, other.l),
            .u = @min(self.u, other.u),
        };
    }

    fn span(self: Range) i64 {
        return self.u - self.l + 1;
    }
};

// TODO opti: BTreeMap or similar
// TODO opti: use unsafe list mgmt
fn parseRanges(allocator: Allocator, block: []const u8) !List(Range) {
    var result = try List(Range).initCapacity(allocator, 200);
    var lines = std.mem.tokenizeScalar(u8, block, '\n');
    while (lines.next()) |range| {
        const len_lower = std.mem.findScalar(u8, range, '-') orelse @panic("invalid range");
        const l = aoc.parse.atoi_stripped(i64, range[0..len_lower]);
        const u = aoc.parse.atoi_stripped(i64, range[len_lower + 1 ..]);

        try result.append(allocator, .{.l = l, .u = u});
    }

    return result;
}

fn findItemLinear(ranges: List(Range), item: i64) bool {
    for (ranges.items) |range| {
        if (item >= range.l and item <= range.u) {
            // std.log.debug("old found: {any}", .{range});
            return true;
        }
    }
    return false;
}

fn findItem(ranges: []const Range, item: i64) bool {
    // const res = std.sort.upperBound(Range, ranges, item, Range.cmpItemL);
    const res = std.sort.partitionPoint(Range, ranges, item, Range.canBeIn);
    // std.log.debug("{any}-->{any}", .{item, res});
    // if (res == null) return false;
    for (ranges[0..res]) |range| {
        // std.log.debug("  testing {any}", .{range});
        // if (item < range.l) return false;
        if (item <= range.u) return true;
    }
    return false;
    // std.log.debug("new found: {any}", .{if (res != null) ranges[res.?] else Range{.l = 0, .u = 0}});
    // return res != null;
}

fn countRange(include: bool, current: Range, remaining: []const Range) i64 {
    var count: i64 = if (include) current.span() else -current.span();
    for (remaining, 0..) |range, i| {
        const intersected = current.intersect(range);
        if (intersected != null) {
            count += countRange(!include, intersected.?, remaining[i+1..]);
        }
    }
    return count;
}

pub fn main() !void {
    const allocator = try aoc.allocator();

    for (0..100) |_| {
        const reader = try aoc.Reader.init(allocator);
        var parts = std.mem.splitSequence(u8, try reader.mmap(), "\n\n");

        // GRIPE: the fact that you can comment out some code and have the rest fail to compile due to unused or unmutated variables with (?) no option to change it is really annoying
    const fresh = try parseRanges(allocator, parts.next() orelse @panic("invalid input: no fresh part"));
        var available = std.mem.tokenizeScalar(u8, parts.next() orelse @panic("invalid input: no available part"), '\n');
        const freshSorted = fresh.items;
        std.sort.heap(Range, freshSorted, {}, Range.lessThan);

        // for (freshSorted, 0..) |range, i| {
        //     // std.log.debug("{d}: {any}", .{i, range});
        // }

        var part1: i64 = 0;
        var part2: i64 = 0;

        while (available.next()) |item| {
            const itemInt = aoc.parse.atoi_stripped(i64, item);
            // TODO opti: find with binary search (I gave up first time)
            // const found = findItemLinear(fresh, itemInt);
            const found = findItem(freshSorted, itemInt);
            // if (foundLinear != found) {
            //     std.log.err("WRONG! item {d}", .{itemInt});
            // }
            if (found) part1 += 1;
        }

        for (freshSorted, 0..) |range, i| {
            const end = @min(freshSorted.len, i+5);
            part2 += countRange(true, range, freshSorted[i+1..end]);
        }

        try aoc.print("{d}\n{d}\n", .{part1, part2});
    }
}