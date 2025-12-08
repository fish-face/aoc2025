const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;

const REPEATS = if (aoc.build_options.repeats > 1) 10 else 1;

const T = i32;
const LIMIT = if (aoc.build_options.sample_mode) 10 else 1000;
const DISTS = if (aoc.build_options.sample_mode) 20 else 1000;
const PAIRS = DISTS * (DISTS - 1) / 2;

fn parseCoord(line: []const u8) [3]T {
    const n1 = std.mem.findScalar(u8, line, ',').?;
    const x = aoc.parse.atoi(T, line[0..n1]);
    const n2 = std.mem.findScalar(u8, line[n1+1..], ',').? + n1+1;
    const y = aoc.parse.atoi(T, line[n1+1..n2]);
    const z = aoc.parse.atoi(T, line[n2+1..]);

    return .{x, y, z};
}

fn dist(a: [3]T, b: [3]T) u64 {
    const a0 = @as(i64, a[0]);
    const a1 = @as(i64, a[1]);
    const a2 = @as(i64, a[2]);
    const b0 = @as(i64, b[0]);
    const b1 = @as(i64, b[1]);
    const b2 = @as(i64, b[2]);
    return @intCast(
        (b0 - a0) * (b0 - a0) +
        (b1 - a1) * (b1 - a1) +
        (b2 - a2) * (b2 - a2)
    );
}

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);

    var p1: usize = 0;
    var p2: usize = 0;

    for (0..REPEATS) |repeat| {
        // var coords = [_][3]T{undefined, undefined, undefined} ** DISTS;
        // var distances = [_]u64{undefined} ** PAIRS;
        // var indices = [_][2]usize{undefined} ** 2 ** PAIRS;
        var coords = try List([3]T).initCapacity(allocator, DISTS);
        var distances = try List(u64).initCapacity(allocator, PAIRS);
        var indices = try List([2]usize).initCapacity(allocator, PAIRS);

        {
            var it = try reader.iterLines();
            var i: usize = 0;
            while (it.next()) |line| {
                const coord = parseCoord(line);
                coords.appendAssumeCapacity(coord);
                for (0..i) |j| {
                    const d = dist(coords.items[j], coord);
                    distances.appendAssumeCapacity(d);
                    indices.appendAssumeCapacity(.{i, j});
                }
                // std.log.debug("{any}", .{coord});
            i += 1;
            }
        }

        const SortCtxt = struct {
            distances: []u64,
            indices: [][2]usize,
            pub fn lessThan(ctx: @This(), a: usize, b: usize) bool {
                return ctx.distances[a] < ctx.distances[b];
            }
            pub fn swap(ctx: @This(), a: usize, b: usize) void {
                std.mem.swap(u64, &ctx.distances[a], &ctx.distances[b]);
                std.mem.swap([2]usize, &ctx.indices[a], &ctx.indices[b]);
            }
        };
        std.mem.sortUnstableContext(
            0,
            PAIRS,
            SortCtxt{.distances = distances.items, .indices = indices.items}
        );
        // std.log.debug("{any}", .{distances.items[0..10]});
        // std.log.debug("{any}", .{indices.items[0..10]});

        var circuits = [_]?u16{null} ** DISTS;
        var p1circuits = [_]?u16{null} ** DISTS;
        var last_pair: [2]usize = undefined;

        for (indices.items, 0..) |idx, n| {
            if (n == LIMIT) {
                p1circuits = circuits;
            }
            const i, const j = idx;
            // TODO is it better to scan the circuits each iteration, rather than going to the end?
            if (circuits[i]) |a| {
                if (circuits[j]) |b| {
                    if (a != b) {
                        // both points already have a circuit assigned; search for those matching a and set them to that of b
                        // std.log.debug("merging {d} --> {d}", .{a, b});
                        for (circuits, 0..) |aa, ii| {
                            if (aa == a) {
                                circuits[ii] = b;
                            }
                        }
                        last_pair = .{i, j};
                    }
                } else {
                    circuits[j] = a;
                    last_pair = .{i, j};
                    // std.log.debug("joining previously isolated: {d} to {d} --> {d}", .{j, i, a});
                }
            } else if (circuits[j]) |b| {
                circuits[i] = b;
                last_pair = .{i, j};
                // std.log.debug("joining previously isolated: {d} to {d} --> {d}", .{i, j, b});
            } else {
                // std.log.debug("joining previously isolated: {d}, {d} --> {d}", .{i, j, n});
                circuits[i] = @intCast(n);
                circuits[j] = @intCast(n);
                last_pair = .{i, j};
            }
        }
        // std.log.debug("{any}", .{circuits});

        // TODO opti track in above loop
        var counts = [_]u16{0} ** DISTS;
        for (p1circuits) |circuit| {
            if (circuit) |c| {
                counts[@intCast(c)] += 1;
            }
        }

        std.mem.sortUnstable(u16, &counts, {}, std.sort.desc(u16));

        // std.log.debug("{any}", .{counts[0..3]});
        // std.log.debug("{any}, {any}", .{coords.items[last_pair[0]], coords.items[last_pair[1]]});

        // GRIPE: you need to create these intermediate values because there is NO WAY to do an intCast from signed to unsigned ints other than into a variable with the type specified. This is even worse than rust's insanely persnickety integer casts.
        const x1: u64 = @intCast(coords.items[last_pair[0]][0]);
        const x2: u64 = @intCast(coords.items[last_pair[1]][0]);

        p1 += @as(u64, counts[0]) * @as(u64, counts[1]) * @as(u64, counts[2]);
        p2 += x1 * x2;

        if (repeat == 0) {
            try aoc.print("{d}\n{d}\n", .{p1, p2});
        }
    }
}
