const std = @import("std");
const aoc = @import("aoc");

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    std.debug.print("Hello, world! All your {s} are belong to us.\n", .{"codebase"});
    try aoc.printf("Hello, world! All your {s} are belong to us.\n", .{"codebase"});
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}

test "simple test" {
    try std.testing.expectEqual(1, 1);
    // try std.testing.expectEqual(1, 2);
}