pub const Reader = @import("reader.zig").Reader;
pub const parallel_map_unordered = @import("parallel.zig").parallel_map_unordered;
pub const parse = @import("parse.zig");
pub const grid = @import("grid.zig");
pub const Grid = grid.Grid;
pub const Pt = @import("coord.zig").Pt;
pub const build_options = @import("build_options");

const std = @import("std");
const Allocator = std.mem.Allocator;

const MEM_SIZE = 1024 * 1024 * 1000; // 1000 MB

pub fn allocator() !Allocator {
    // return std.heap.c_allocator;
    return std.heap.page_allocator;
    // GRIPE: why is unreachable code a compile error?
}

pub fn fixed_allocator() !Allocator {
    const heap = std.heap.page_allocator;
    const memory_buffer = try heap.alloc(
        u8, MEM_SIZE,
    );
    const fba = try heap.create(std.heap.FixedBufferAllocator);
    fba.* = .init(memory_buffer);
    return fba.allocator();
}

pub fn print(comptime fmt: []const u8, args: anytype) !void {
    // GRIPE: why do I have to write this function myself
    var buf: [1024]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buf);
    const stdout = &writer.interface;

    try stdout.print(fmt, args);
    try stdout.flush();
}
