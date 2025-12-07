const std = @import("std");
const List = std.ArrayList;

const aoc = @import("aoc");
const Allocator = std.mem.Allocator;
const Grid = aoc.grid.PaddedGrid(u8, 1);
const Pt = aoc.Pt;

fn accessible(grid: Grid, p: usize) bool {
    // std.log.debug("{d} {any}", .{p, grid.ati(p)});
    if (grid.ati(p)) |v| {
        if (v == '.') {
            return false;
        } else {
            return v < 4;
        }
    }
    return false;
}

fn preprocessGrid(grid: *Grid, queue: *List(usize)) void {
    var coords = grid.coords();
    while (coords.next()) |p| {
        var n_neighbours: u8 = 0;
        if (grid.ati(p).? == '.') {
            continue;
        }
        for (grid.neighbours8(p)) |q| {
            if (grid.ati(q)) |v| {
                if (v != '.') {
                    n_neighbours += 1;
                }
            }
        }
        grid.seti(p, n_neighbours);
        if (n_neighbours < 4) {
            queue.appendAssumeCapacity(p);
        }
    }
    // std.log.debug("{f}", .{grid});
}

// I'm sticking with the name
fn prat2(grid: *Grid, queue: *List(usize)) usize {
    var removed: usize = 0;
    var removed_any = true;
    // TODO opti: bitset/vec?

    while (queue.pop()) |p| {
        if (accessible(grid.*, p)) {
            removed += 1;
            removed_any = true;
            grid.seti(p, '.');
            for (grid.neighbours8(p)) |q| {
                if (grid.ati(q)) |qv| {
                    if (qv > 0 and qv != '.') {
                        grid.seti(q, qv - 1);
                    }
                    if (qv == 4) {
                        queue.appendAssumeCapacity(q);
                    }
                }
            }
        }
    }

    return removed;
}

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);

    // std.log.debug("{f}", .{grid});

    var p1: usize = 0;
    var p2: usize = 0;

    for (0..aoc.build_options.repeats) |_| {
        var grid = try reader.readPaddedGrid(1);

        var buffer = [_]usize{undefined} ** (40000);
        var queue = List(usize).initBuffer(&buffer);
        preprocessGrid(&grid, &queue);
        p1 += queue.items.len;
        p2 += prat2(&grid, &queue);
    }

    try aoc.print("{d}\n{d}\n", .{p1, p2});
}
