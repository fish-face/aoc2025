const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;

const Edge = struct {
    v: i64,
    start: bool,

    fn lessThan(_: void, self: Edge, other: Edge) bool {
        return self.v < other.v;
    }
};

fn parseRanges(block: []const u8, edges: []Edge) !usize {
    var lines = std.mem.tokenizeScalar(u8, block, '\n');
    var i: usize = 0;

    while (lines.next()) |line| {
        const len_lower = std.mem.findScalar(u8, line, '-') orelse @panic("invalid range");
        const l = aoc.parse.atoi_stripped(i64, line[0..len_lower]);
        const u = aoc.parse.atoi_stripped(i64, line[len_lower + 1 ..]);

        edges[i * 2] = .{.v = l, .start = true};
        edges[i * 2 + 1] = .{.v = u, .start = false};
        i += 1;
    }

    std.sort.block(Edge, edges[0..i * 2], {}, Edge.lessThan);

    return i * 2;
}

fn solve(edges: []const Edge, available: []i64) [2]i64 {
    var part1: i64 = 0;
    var part2: i64 = 0;

    var depth: i32 = 1;
    var pos = edges[0].v;
    var item_ptr: usize = 0;
    var item: i64 = available[item_ptr];

    while (item < pos) {
        item_ptr += 1;
        item = available[item_ptr];
    }

    for (edges[1..]) |edge| {
        while (item_ptr < available.len and ((depth > 0 and item <= edge.v) or (item < edge.v))) {
            if (depth > 0) {
                part1 += 1;
            } else {
            }
            item_ptr += 1;
            if (item_ptr < available.len) {
                item = available[item_ptr];
            }
        }
        if (depth == 0 and edge.v == pos) part2 -= 1;
        if (depth > 0) {
            part2 += edge.v - pos;
        }
        if (edge.start) {
            depth += 1;
        } else {
            depth -= 1;
        }
        if (depth == 0) part2 += 1;
        pos = edge.v;
    }
    return .{part1, part2};
}

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);
    var part1: i64 = undefined;
    var part2: i64 = undefined;
    for (0..aoc.build_options.repeats) |_| {
        var parts = std.mem.splitSequence(u8, try reader.mmap(), "\n\n");

        // GRIPE: the fact that you can comment out some code and have the rest fail to compile due to unused or unmutated variables with (?) no option to change it is really annoying

        var edges: [512]Edge = undefined;
        const num_edges = try parseRanges(parts.next() orelse @panic("invalid input: no fresh part"), &edges);
        var available: [2048]i64 = .{0} ** 2048;
        const num_available = aoc.parse.parseInts(
            i64,
            &available,
            parts.next() orelse @panic("invalid input: no available part"),
            '\n',
        );

        std.mem.sort(i64, available[0..num_available], {}, std.sort.asc(i64));

        part1, part2 = solve(edges[0..num_edges], available[0..num_available]);
    }

    try aoc.print("{d}\n{d}\n", .{part1, part2});
}
