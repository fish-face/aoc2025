const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;

const Pt = aoc.Pt;

const WIDTH = if (aoc.build_options.sample_mode) 11 else 100000;
const POINTS = if (aoc.build_options.sample_mode) 9 else 1024;

const REPEATS = if (aoc.build_options.repeats > 1) 10 else 1;

fn lessThan(_: void, a: Pt(u64), b: Pt(u64)) bool {
    return a.y < b.y or (a.y == b.y and a.x < b.x);
}

fn lessThan3(_: void, a: [3]u64, b: [3]u64) bool {
    return a[0] < b[0] or
        (a[0] == b[0] and a[1] < b[1]) or
        (a[0] == b[0] and a[1] == b[1] and a[2] < b[2]);
}

fn area(p: Pt(u64), q: Pt(u64)) u64 {
    const w = if (p.x > q.x) p.x - q.x else q.x - p.x;
    const h = if (p.y > q.y) p.y - q.y else q.y - p.y;

    return (w+1) * (h+1);
}

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);

    var p1: usize = 0;
    var p2: usize = 0;

    for (0..REPEATS) |repeat| {
        var lines = try reader.iterLines();
        var points = [_]Pt(u64){undefined} ** POINTS;
        var pointset = std.AutoHashMapUnmanaged(Pt(u64), void).empty;
        try pointset.ensureTotalCapacity(allocator, @intCast(POINTS));

        var n_points: usize = 0;
        var n_xpoints: usize = 0;
        var n_ypoints: usize = 0;
        var best_area: u64 = 0;

        var y_divs_ = [_]u64{undefined} ** POINTS;
        var x_divs_ = [_][3]u64{[3]u64{undefined, undefined, undefined}} ** POINTS;
        var pp: ?Pt(u64) = null;

        while (lines.next()) |line| {
            var point = [_]u64{undefined} ** 2;
            // TODO opti: _stripped is not necessary in parseInts today... was it ever?
            _ = aoc.parse.parseInts(u64, &point, line, ',');
            if (point[0] == 0) {
                std.log.debug("{s}", .{line});
            }

            const p = Pt(u64){.x = point[0], .y = point[1]};
            points[n_points] = p;
            pointset.putAssumeCapacity(p, {});
            if (pp) |ppp| {
                if (p.y == ppp.y) {
                    y_divs_[n_ypoints] = p.y;
                    n_ypoints += 1;
                } else if (p.y > ppp.y) {
                    x_divs_[n_xpoints] = .{p.x, ppp.y, p.y};
                    n_xpoints += 1;
                } else if (p.y < ppp.y) {
                    x_divs_[n_xpoints] = .{p.x, p.y, ppp.y};
                    n_xpoints += 1;
                }
            }
            pp = p;

            for (points[0..n_points]) |q| {
                best_area = @max(best_area, area(p, q));
            }
            n_points += 1;
        }

        if (pp) |ppp| {
            const p = points[0];
            if (p.y == ppp.y) {
                y_divs_[n_ypoints] = p.y;
                n_ypoints += 1;
            } else if (p.y > ppp.y) {
                x_divs_[n_xpoints] = .{p.x, ppp.y, p.y};
                n_xpoints += 1;
            } else if (p.y < ppp.y) {
                x_divs_[n_xpoints] = .{p.x, p.y, ppp.y};
                n_xpoints += 1;
            }
        }

        const x_divs = x_divs_[0..n_xpoints];
        const y_divs = y_divs_[0..n_ypoints];
        std.log.debug("{any}", .{y_divs});
        std.log.debug("{any}", .{x_divs});
        std.mem.sortUnstable([3]u64, x_divs, {}, lessThan3);
        std.mem.sortUnstable(u64, y_divs, {}, std.sort.asc(u64));

        const buf = try allocator.alloc(bool, n_xpoints * n_ypoints);
        defer allocator.free(buf);
        @memset(buf, false);
        var condensed_grid = aoc.Grid(bool){
            .data = buf,
            .width = n_xpoints,
            .height = n_ypoints,
        };

        var x_to_div = std.AutoHashMap(u64, usize).init(allocator);
        var y_to_div = std.AutoHashMap(u64, usize).init(allocator);
        defer x_to_div.deinit();
        defer y_to_div.deinit();

        var y_prev = y_divs[0];
        var x_prev: u64 = 0;
        var inside = false;

        // We now have an ordered list of x and y coordinates, where (e.g.) an x entry indicates that there was a
        // line on that x coordinate somewhere.
        // We walk the resulting grid of crossing points. Only some of these crossing points correspond to points in the
        // original list. The first objective is to work out whether the rectangle formed by the current point and the
        // previous X coordinate plus the Y coordinate of the previous layer is a rectangle *inside* or *outside* the
        // shape.
        // We do this by detecting when we go across an x coordinate whose corresponding line segment includes the y
        // layer we are on: this represents us crossing from inside to outside, or outside to inside, the shape.
        try y_to_div.put(y_divs[0], 0);
        for (y_divs[1..], 1..) |y, j| {
            try y_to_div.put(y, j);
            for (x_divs[0..], 0..) |x_, i| {
                const x, const ya, const yb = x_;

                try x_to_div.put(x, i);
                if (x_prev <= x) {
                    // otherwise we are transitioning from the final column back to the first column on a new layer
                    if (inside) {
                        if (i == 2 and j == 3) {
                            std.log.warn("{d}({d}) {d}({d})", .{x, i, y, j});
                        }
                        condensed_grid.set(
                            .{.x = i, .y = j},
                            true,
                        );

                    } else {

                    }
                }
                if (y > ya and y <= yb) {
                    inside = !inside;
                }
                x_prev = x;
            }
            y_prev = y;
        }

        for (points[0..n_points-1], 0..) |p, i| {
            main: for (points[i+1..n_points]) |q| {
                const left = if (p.x < q.x) p else q;
                const right = if (p.x >= q.x) p else q;
                const top = if (p.y < q.y) p else q;
                const bottom = if (p.y >= q.y) p else q;

                const xd_left = x_to_div.get(left.x).? + 1;
                const xd_right = x_to_div.get(right.x).?;
                const yd_top = y_to_div.get(top.y).? + 1;
                const yd_bottom = y_to_div.get(bottom.y).?;

                //         left   right
                //        /      /
                //        |   |  |  |
                // top  --+---+--+--+--
                //        |XXX|XX|  |
                //        |XXX|XX|  |
                //      --+---+--+--+--
                //        |   |XX|  |
                // bot  --+---+--+--+--
                //
                for (x_divs[xd_left..], xd_left..) |x_, ii| {
                    const x = x_[0];
                    if (yd_top >= condensed_grid.height) continue :main;
                    if (yd_bottom >= condensed_grid.height) continue :main;
                    if (!condensed_grid.at(.{.x = ii, .y = yd_top})) continue :main;
                    if (!condensed_grid.at(.{.x = ii, .y = yd_bottom})) continue :main;
                    if (x >= right.x) break;
                }

                for (y_divs[yd_top..], yd_top..) |y, ii| {
                    if (y >= bottom.y) break;
                    if (!condensed_grid.at(.{.y = ii, .x = xd_left})) continue :main;
                    if (!condensed_grid.at(.{.y = ii, .x = xd_right})) continue :main;
                }

                p2 = @max(p2, area(p, q));
            }
        }

        p1 += best_area;
        p2 += 0;
        if (repeat == 0) {
            try aoc.print("{d}\n{d}\n", .{p1, p2});
        }
    }
}
