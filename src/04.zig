const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;
const Grid = aoc.grid.PaddedGrid(u8, 1);
const Pt = aoc.Pt;

fn accessible(grid: Grid, p: usize) bool {
    // std.log.debug("{d} {any}", .{p, grid.ati(p)});
    if (grid.ati(p)) |v| {
        if (v != '@') {
            return false;
        }
    }
    var n_neighbours: usize = 0;
    for (grid.neighbours8(p)) |q| {
        // if (p == 39) {
        //     std.log.debug("  {d}", .{q});
        // }
        if (grid.ati(q)) |v| {
            if (v == '@') {
                n_neighbours += 1;
            }
        }
    }
    return n_neighbours < 4;
}

fn part1(grid: Grid) usize {
    var it = grid.coords();
    var n_accessible: usize = 0;

    while (it.next()) |p| {
        // UNGRIPE: I worked out how to cast bool to int, the name is just a bit weird
        n_accessible += @intFromBool(accessible(grid, p));
    }
    return n_accessible;
}

// I'm sticking with the name
fn prat2(grid: *Grid) usize {
    var removed: usize = 0;
    var removed_any = true;

    while (removed_any) {
        var it = grid.coords();
        removed_any = false;
        while (it.next()) |p| {
            if (accessible(grid.*, p)) {
                removed += 1;
                removed_any = true;
                grid.seti(p, 'x');
            }
        }
        // std.log.debug("{f}", .{grid.*});
    }


    return removed;
}

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);

    var grid = try reader.readPaddedGrid(1);
    // std.log.debug("{f}", .{grid});

    const p1 = part1(grid);
    const p2 = prat2(&grid);
    // const p2 = 0;

    try aoc.print("{d}\n{d}\n", .{p1, p2});
}
