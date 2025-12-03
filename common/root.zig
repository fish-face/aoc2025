pub const Reader = @import("reader.zig").Reader;
pub const parallel_for = @import("parallel.zig").parallel_for;

const std = @import("std");
const Allocator = std.mem.Allocator;

const MEM_SIZE = 1024 * 1024 * 100; // 100 MB

pub fn allocator() !Allocator {
    return std.heap.page_allocator;
    // TODO reinstate
    // GRIPE: why is unreachable code a compile error?
    // const heap = std.heap.page_allocator;
    // const memory_buffer = try heap.alloc(
    //     u8, MEM_SIZE,
    // );
    // // defer heap.free(memory_buffer);
    // const fba = try heap.create(std.heap.FixedBufferAllocator);
    // fba.* = .init(memory_buffer);
    // return fba.allocator();
}

pub fn print(comptime fmt: []const u8, args: anytype) !void {
    // GRIPE: why do I have to write this function myself
    var buf: [1024]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buf);
    const stdout = &writer.interface;

    try stdout.print(fmt, args);
    try stdout.flush();
}
