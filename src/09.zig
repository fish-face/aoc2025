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

        // // 0=N, 1=E, 2=S, 3=W
        // for (points[1..n_points], 1..) |p, i| {
        //     var q = p;
        //     var dir: i8 = undefined;
        //     var prev_dir: ?i8 = null;
        //     for (points[i+1..]) |qq| {
        //         if (qq.y < q.y) {
        //             dir = 0;  // N
        //         } else if (qq.x > q.x) {
        //             dir = 1;  // W
        //         } else if (qq.y > q.y) {
        //             dir = 2;  // S
        //         } else if (qq.x < q.x) {
        //             dir = 3;
        //         }
        //
        //         if (prev_dir) |dd| {
        //             // 1=L, -1=R
        //             const turn = (dir - dd) % 4;
        //         }
        //
        //         prev_dir = dir;
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
        // var maxRectState = [_]maxRectInfo{.{.h = 0, .hl = 0, .hr = 0, .w = 0, .bottom_left = false, .bottom_right = false}} ** POINTS;
        var maxRectState = std.mem.zeroes([POINTS]maxRectInfo);
        var y_prev = y_divs[0];
        var x_prev: u64 = 0;
        // var a: u64 = 0;
        var inside = false;

        // TODO make better
        // Create boundaries
        for (0..n_xpoints) |i| {
            maxRectState[i].r = x_divs[i][0];
        }
        // maxRectState[n_xpoints-1].r = x_divs[x_divs.len-1][0] + 0;

        // We now have an ordered list of x and y coordinates, where (e.g.) an x entry indicates that there was a
        // line on that x coordinate somewhere.
        // We walk the resulting grid of crossing points. Only some of these crossing points correspond to points in the
        // original list. The first objective is to work out whether the rectangle formed by the current point and the
        // previous X coordinate plus the Y coordinate of the previous layer is a rectangle *inside* or *outside* the
        // shape.
        // We do this by detecting when we go across an x coordinate whose corresponding line segment includes the y
        // layer we are on: this represents us crossing from inside to outside, or outside to inside, the shape.
        for (y_divs[1..]) |y| {
            for (x_divs[0..], 0..) |x_, i| {
                const x, const ya, const yb = x_;

                // std.log.debug("? {d}: {d},{d} --> {s}", .{y, ya, yb, if(!(y > ya and y <= yb)) "flip" else "stay"});
                if (x_prev <= x) {
                    // otherwise we are transitioning from the final column back to the first column on a new layer
                    if (inside) {
                        const h = y - y_prev;
                        const w = x - x_prev;
                        std.log.debug(
                            "rect {s}: {d: >2},{d: >2}--{d: >2},{d: >2} {d: >2}|{d: >2}-{d: >2}",
                            .{if (inside) " in" else "out", x_prev, y_prev, x, y, y, ya, yb});
                        const top_left = pointset.contains(.{.x = x_prev, .y = y_prev});
                        const top_right = pointset.contains(.{.x = x, .y = y_prev});
                        const bottom_left = pointset.contains(.{.x = x_prev, .y = y});
                        const bottom_right = pointset.contains(.{.x = x, .y = y});
                        const curState = maxRectState[i];
                        maxRectState[i] = .{
                            .h = curState.h + h,
                            .hl = if (curState.hl == 0 and !top_left) 0 else curState.hl + h,
                            .hr = if (curState.hr == 0 and !top_right) 0 else curState.hr + h,
                            .w = w,
                            .l = x_prev,
                            .r = x,
                            .bottom_left = bottom_left,
                            .bottom_right = bottom_right,
                        };
                        // std.log.debug("{any}, {any}", .{top_left, top_right});
                    } else {
                        maxRectState[i].h = 0;
                        maxRectState[i].hl = 0;
                        maxRectState[i].hr = 0;
                    }
                }
                if (y > ya and y <= yb) {
                    inside = !inside;
                    // std.log.debug("flip to {s}", .{if (inside) "y" else "n"});
                }
                x_prev = x;
            }
            p2 = @max(p2, maxArea(maxRectState[0..n_xpoints], n_xpoints));
            y_prev = y;
        }


        p1 += best_area;
        p2 += 0;
        if (repeat == 0) {
            try aoc.print("{d}\n{d}\n", .{p1, p2});
        }
    }
}
