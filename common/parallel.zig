const std = @import("std");
const Allocator = std.mem.Allocator;
const Thread = std.Thread;
const List = std.ArrayList;

// GRIPE: without proper interfaces, we have to just YOLO the iterator's type and get horrible compilation errors
// pub fn parallel_map(allocator: Allocator, iterator: anytype, comptime T: type, f: fn(anytype) T) T {
//     var pool: Thread.Pool = undefined;
//     try pool.init(.{
//         .allocator = allocator,
//     });
//     defer pool.deinit();
//     // const n_threads = pool.getIdCount();
//     // var i: usize = 0;
//     var result = List(T);
//     result.initCapacity(allocator, 16);
//
//     while (iterator.next()) |item| {
//         // const job_idx = i % n_threads;
//         try pool.spawn(work, .{result, T, item});
//         // i += 1;
//     }
// }
//
// fn work(result: )