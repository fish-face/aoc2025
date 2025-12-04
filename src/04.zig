const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;
const Grid = aoc.Grid;
const Pt = aoc.Pt;

fn accessible(grid: Grid(u8), p: Pt(usize)) bool {
    if (grid.at(p) != '@') {
        return false;
    }
    var n_neighbours: usize = 0;
    for (grid.neighbours8(p)) |q| {
        if (q != null and grid.at(q.?) == '@') {
            n_neighbours += 1;
        }
    }
    return n_neighbours < 4;
}

fn part1(grid: Grid(u8)) usize {
    var it = grid.coords();
    var n_accessible: usize = 0;

    while (it.next()) |p| {
        // UNGRIPE: I worked out how to cast bool to int, the name is just a bit weird
        n_accessible += @intFromBool(accessible(grid, p));
    }
    return n_accessible;
}

// I'm sticking with the name
fn prat2(grid: *Grid(u8)) usize {
    var removed: usize = 0;
    var removed_any = true;

    while (removed_any) {
        var it = grid.coords();
        removed_any = false;
        while (it.next()) |p| {
            if (accessible(grid.*, p)) {
                removed += 1;
                removed_any = true;
                grid.set(p, 'x');
            }
        }
    }

    return removed;
}
pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);
    var grid = try reader.readGrid();

    const p1 = part1(grid);
    const p2 = prat2(&grid);

    try aoc.print("{d}\n{d}\n", .{p1, p2});
}
