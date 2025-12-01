const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.array_list.Managed;

pub const Reader = struct {
    allocator: Allocator,
    path: []const u8,

    pub fn init(alloc: Allocator) !Reader {
        var args = std.process.args();
        _ = args.next();
        const path = args.next() orelse "";
        return .{
            .allocator = alloc,
            .path = path,
        };
    }

    /// Split on newline and return strings
    pub fn readLines(self: Reader) !List([] const u8) {
        const input = try self.read();
        var it = std.mem.splitScalar(u8, input, '\n');
        var result = List([] const u8).init(self.allocator);
        while (it.next()) |line| {
            // GRIPE: we haven't learnt that manually incrementing iterators is just boring? And yet we have a foreach???
            if (line.len > 0) {
                try result.append(line);
            }
        }
        return result;
    }

    /// Split on newline and pass through a parse function
    pub fn parseLines(self: Reader, comptime T: type, f: fn (Allocator, []const u8) anyerror!T) !List(T) {
        const input = try self.mmap();
        var it = std.mem.splitScalar(u8, input, '\n');
        var result = List(T).init(self.allocator);
        while (it.next()) |line| {
            // GRIPE: we haven't learnt that manually incrementing iterators is just boring? And yet we have a foreach???
            if (line.len > 0) {
                try result.append(try (f(self.allocator, line)));
            }
        }
        return result;
    }

    // pub fn foldLines(self: Reader, comptime T: type, f: fn (Allocator, []const u8, T) T) T {
    //
    // }

    /// Read entire file to a string
    fn read(self: Reader) ![]const u8 {
        return std.fs.cwd().readFileAlloc(self.path, self.allocator, .unlimited);
    }

    fn mmap(self: Reader) ![] u8 {
        const file = try std.fs.cwd().openFile(self.path, .{});
        const handle = file.handle;
        const stats = try std.posix.fstat(handle);
        return std.posix.mmap(
            null,
            @intCast(stats.size),
            std.posix.PROT.READ,
            .{.TYPE = .SHARED},
            handle,
            0,
        );
    }

    // TODO maybe a function to split as the input is read, rather than afterwards
    // fn readDelimiter(self: Reader, delim: []const u8) !List([] const u8) {
    //     var file = try std.fs.cwd().openFile(self.path);
    //     defer file.close();
    //
    //     var buf: [1024]u8 = undefined;
    //     var reader = file.reader(&buf);
    //     const input = &reader.interface;
    //     return try input.readAlloc(self.allocator, try file.getEndPos());
    // }
};
