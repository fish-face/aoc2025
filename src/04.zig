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
    // var n_neighbours: usize = 0;
    // for (grid.neighbours8(p)) |q| {
    //     if (grid.ati(q)) |v| {
    //         if (v == '@') {
    //             n_neighbours += 1;
    //         }
    //     }
    // }
    // return n_neighbours < 4;
}

// TODO opti: store starting queue of accessible locs to do part2
fn preprocessGrid(grid: *Grid) usize {
    var coords = grid.coords();
    var num_accessible: usize = 0;
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
        if (n_neighbours < 4) num_accessible += 1;
    }
    // std.log.debug("{f}", .{grid});

    return num_accessible;
}

// fn part1(grid: Grid) usize {
//     var it = grid.coords();
//     var n_accessible: usize = 0;
//
//     while (it.next()) |p| {
//         // UNGRIPE: I worked out how to cast bool to int, the name is just a bit weird
//         n_accessible += @intFromBool(accessible(grid, p));
//     }
//     return n_accessible;
// }

// I'm sticking with the name
fn prat2(grid: *Grid) [2]usize {
    // var part1: usize = 0;
    var removed: usize = 0;
    var removed_any = true;
    // TODO opti: bitset/vec?
    var buffer = [_]usize{undefined} ** (40000);
    var queue = List(usize).initBuffer(&buffer);
    var coords = grid.coords();
    while (coords.next()) |p| {
        queue.appendAssumeCapacity(p);
        // if (accessible(grid.*, p)) {
        //     part1 += 1;
        //     queue.appendAssumeCapacity(p);
        // }
    }

    while (queue.pop()) |p| {
        if (accessible(grid.*, p)) {
            removed += 1;
            removed_any = true;
            grid.seti(p, '.');
            for (grid.neighbours8(p)) |q| {
                if (grid.ati(q)) |qv| {
                    if (qv > 0) {
                        grid.seti(q, qv - 1);
                    }
                    queue.appendAssumeCapacity(q);
                }
            }
        }
    }

    return .{0, removed};
}

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);

    var grid = try reader.readPaddedGrid(1);
    // std.log.debug("{f}", .{grid});

    var p1: usize = 0;
    var p2: usize = 0;

    for (0..1) |_| {
        // p1 += part1(grid);
        const pp1 = preprocessGrid(&grid);
        _, const pp2 = prat2(&grid);
        p1 += pp1;
        p2 += pp2;
    }

    try aoc.print("{d}\n{d}\n", .{p1, p2});
}
