const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;

const Pt = aoc.Pt;

const WIDTH = if (aoc.build_options.sample_mode) 11 else 100000;
const POINTS = if (aoc.build_options.sample_mode) 9 else 1024;

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

const maxRectInfo = struct {
    h: u64,
    hl: u64,
    hr: u64,
    w: u64,
    l: u64,
    r: u64,
    bottom_left: bool,
    bottom_right: bool,
};

fn maxArea(maxRectState: []maxRectInfo, n: usize) u64 {
    // var left = [_]?maxRectInfo{null} ** POINTS;
    // var left = [_]?u64{null} ** POINTS;
    // TODO is POINTS the correct initial val?
    // var right = [_]?u64{null} ** POINTS;
    // var right = std.mem.zeroes([POINTS]maxRectInfo);
    // var right = right_[0..n_ypoints];
    var buffer = [_]u64{undefined} ** POINTS;
    var stack = List(u64).initBuffer(&buffer);
    var a: u64 = 0;

    // maximal histogram algorithm
    // TODO YOU WERE HERE
    //      just checking whether we end up with a rectangle with opposite corners among the points is not enough
    //      because we could pass over a valid rectangle on the way to a larger one and never check it
    for (maxRectState[0..n], 0..) |state, i| {
        std.log.debug("{any}", .{state});
        while (stack.getLastOrNull() != null and maxRectState[stack.getLast()].h >= state.h) {
            const bar = stack.pop().?;
            const prev_smaller = stack.getLastOrNull();
            if (prev_smaller) |prev_smaller_| {
                const l = maxRectState[prev_smaller_].r;
                const r = state.r;
                // const l = prev_smaller_;
                // const r = i;
                const h = maxRectState[bar].h;
                const valid = (
                    (maxRectState[prev_smaller_+1].hl == h and state.bottom_right) or
                    (maxRectState[prev_smaller_+1].bottom_left and state.hr == h)
                );
                std.log.debug("{d}--{d}x{d}, {any}", .{l, r, h, valid});
                if (valid) a = @max(a, (r - l + 1) * (h + 1));
            }
        }

        stack.appendAssumeCapacity(i);

        // while (stack.getLastOrNull() != null and stack.getLast().h >= state.h) {
        //     _ = stack.pop();
        // }
        // left[i] = stack.getLastOrNull();
        // stack.appendAssumeCapacity(state);
    }

    while (stack.pop()) |bar| {
        const prev_smaller = stack.getLastOrNull();
        if (prev_smaller) |prev_smaller_| {
            const l = maxRectState[prev_smaller_].r;
            const r = maxRectState[n-1].r;
            // const l = prev_smaller_;
            // const r = n-1;
            const h = maxRectState[bar].h;
            const valid = (
                (maxRectState[prev_smaller_+1].hl == h and maxRectState[n-1].bottom_right) or
                (maxRectState[prev_smaller_+1].bottom_left and maxRectState[n-1].hr == h)
            );
            std.log.debug("{d}--{d}x{d}, {any}", .{l, r, h, valid});
            if (valid) a = @max(a, (r - l + 1) * (h + 1));
        }
    }

    // for (0..n) |ii| {
    //     const i = n - ii - 1;
    //     const state = maxRectState[i];
    //     while (stack.getLastOrNull() != null and stack.getLast().h >= state.h) {
    //         _ = stack.pop();
    //     }
    //     right[i] = stack.getLastOrNull();
    // }
    // std.log.debug("{any}", .{left});
    // var max: u64 = 0;
    // for (maxRectState, 0..) |state, i| {
    //     if (right[i]) |r| {
    //         if (left[i]) |l| {
    //             std.log.debug("{any} {any}", .{r, l});
    //             max = @max(max, ( r.r - l.l ) * state.h);
    //         }
    //     }
    // }
    std.log.debug("{d}", .{a});

    return a;
}

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);

    var p1: usize = 0;
    var p2: usize = 0;

    for (0..aoc.build_options.repeats) |repeat| {
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

        // // min_x[i][j] = minimum x value on path from point i to point j, etc
        // var min_x = [_][POINTS]u64{[POINTS]u64{undefined} ** POINTS} ** POINTS;
        // var max_x = [_][POINTS]u64{[POINTS]u64{undefined} ** POINTS} ** POINTS;
        // var min_y = [_][POINTS]u64{[POINTS]u64{undefined} ** POINTS} ** POINTS;
        // var max_y = [_][POINTS]u64{[POINTS]u64{undefined} ** POINTS} ** POINTS;
        // for (points[0..n_points-1], 0..) |p, i| {
        //     @memset(min_x[i], p.x);
        //     @memset(max_x[i], p.x);
        //     @memset(min_y[i], p.y);
        //     @memset(max_y[i], p.y);
        //     for (points[i+1..], i+1..) |qq, j| {
        //         min_x[i][j] = @min(p.x, qq.x);
        //         max_x[i][j] = @min(p.x, qq.x);
        //         min_y[i][j] = @min(p.y, qq.y);
        //         max_y[i][j] = @min(p.y, qq.y);
        //     }
        // }
        //
        // for (points[0..n_points-1], 0..) |p, i| {
        //     for (points[i+1..], i+1..) |qq, j| {
        //     }
        // }

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
        var y_prev = y_divs[0];
        var x_prev: u64 = 0;
        var inside = false;


        // const GridInfo = struct {
        //     inside: bool = false,
        //     bottom: u64,
        //     right: u64,
        // };
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

                // std.log.debug("? {d}: {d},{d} --> {s}", .{y, ya, yb, if(!(y > ya and y <= yb)) "flip" else "stay"});
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
                            // .{.inside = true, .bottom = y, .right = x}
                        );

                    } else {

                    }
                }
                if (y > ya and y <= yb) {
                    inside = !inside;
                    // std.log.debug("flip to {s}", .{if (inside) "y" else "n"});
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
                const priv_q = Pt(u64){.x = 2, .y = 3};
                const priv_p = Pt(u64){.x = 9, .y = 5};
                for (x_divs[xd_left..], xd_left..) |x_, ii| {
                    const x = x_[0];
                    if (priv_p.x == p.x and priv_p.y == p.y and priv_q.x == q.x and priv_q.y == q.y) {
                        std.log.debug("walking horizontally {d} ({d}) {d}, {d}: {any} {any}", .{
                            x, ii, yd_top, yd_bottom,
                            condensed_grid.at(.{.x = ii, .y = yd_top}),
                            condensed_grid.at(.{.x = ii, .y = yd_bottom}),
                        });
                    }
                    // std.log.debug("{d} {d} {d}x{d}", .{ii, yd_top, condensed_grid.width, condensed_grid.height});
                    if (yd_top >= condensed_grid.height) continue :main;
                    if (yd_bottom >= condensed_grid.height) continue :main;
                    if (!condensed_grid.at(.{.x = ii, .y = yd_top})) continue :main;
                    if (!condensed_grid.at(.{.x = ii, .y = yd_bottom})) continue :main;
                    if (x >= right.x) break;
                }

                for (y_divs[yd_top..], yd_top..) |y, ii| {
                    if (priv_p.x == p.x and priv_p.y == p.y and priv_q.x == q.x and priv_q.y == q.y) {
                        std.log.debug("walking vertically {d} ({d}) {d}, {d}: {any} {any}", .{
                            y, ii, xd_left, xd_right,
                            condensed_grid.at(.{.y = ii, .x = xd_left}),
                            condensed_grid.at(.{.y = ii, .x = xd_right}),
                        });
                    }
                    if (y >= bottom.y) break;
                    if (!condensed_grid.at(.{.y = ii, .x = xd_left})) continue :main;
                    if (!condensed_grid.at(.{.y = ii, .x = xd_right})) continue :main;
                }

                // std.log.debug("valid {any}--{any} = {d}", .{p, q, area(p, q)});
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
