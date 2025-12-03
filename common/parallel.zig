const std = @import("std");
const Allocator = std.mem.Allocator;
const Thread = std.Thread;
const List = std.ArrayList;

// GRIPE: without proper interfaces, we have to just YOLO the iterator's type and get horrible compilation errors
pub fn parallel_map_unordered(allocator: Allocator, iterator: anytype, comptime T: type, comptime S: type, f: fn (S) T) !List(T) {
    var pool: Thread.Pool = undefined;
    var lock = Thread.RwLock{};
    var itercopy = iterator;

    try pool.init(.{
        .allocator = allocator,
    });
    // GRIPE: This is less a gripe more "a shame". It would be natural to `defer pool.deinit()` but you can't, because this is the only way to also join the pool, which you need to do *before* returning, so that you have the entire value to return.
    // defer pool.deinit();
    var result = try List(T).initCapacity(allocator, 16);

    while (itercopy.next()) |item| {
        try pool.spawn(work, .{ allocator, &lock, T, S, &result, f, item });
    }

    pool.deinit();

    return result;
}

fn work(allocator: Allocator, lock: *Thread.RwLock, comptime T: type, comptime S: type, result: *List(T), f: fn (S) T, item: S) void {
    const val = f(item);

    {
        lock.lock();
        // UNGRIPE: defer is nice for locks, just as it is with allocations. Something akin to python's context manager's would be even better though, because there's not really any need to have the default method of allocation leave open the possibility that you don't free; just make `alloc` or `lock` be a special kind of call which consists of a regular call and a deferred call. Each of those functions can be exposed individually to permit dealing with them outside the deferral mechanism.
        defer lock.unlock();

        // GRIPE cannot return errors from threads
        result.append(allocator, val) catch {
            std.log.err("error in thread, glhf", .{});
            @panic("error in thread, glhf");
        };
    }
}

fn double(x: u64) u64 {
    return x * 2;
}

const ArrayIterator = struct {
    array: []const u64,
    i: usize = 0,
    fn next(self: *ArrayIterator) ?u64 {
        if (self.i < self.array.len) {
            self.i += 1;
            return self.array[self.i - 1];
        }
        return null;
    }
};

test "basic map" {
    const allocator = std.heap.page_allocator;
    const nums = [_]u64{1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
    // GRIPE: no way to get a """standard""" iterator from an array or slice. Maybe ArrayList allows it.
    const iter = ArrayIterator{
        .array = &nums,
    };
    const res = try parallel_map_unordered(allocator, iter, u64, u64, double);
    std.mem.sort(u64, res.items, {}, std.sort.asc(u64));
    try std.testing.expectEqualDeep(res.items, &[_]u64{2, 4, 6, 8, 10, 12, 14, 16, 18, 20});
}