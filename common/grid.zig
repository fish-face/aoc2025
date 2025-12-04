const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const Pt = @import("coord.zig").Pt;

pub fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();

        data: []T = undefined,
        width: usize = undefined,
        height: usize = undefined,

        pub fn init(data: []T, width: usize) Self {
            return .{
                .data = data,
                .width = width,
                .height = data.len / width,
            };
        }

        pub fn at(self: Self, p: Pt(usize)) T {
            return self.at2(p.x, p.y);
        }
        // GRIPE: no operator overloading, no function overloading
        pub fn at2(self: Self, x: usize, y: usize) T {
            return self.data[x + y * self.width];
        }

        pub fn set(self: *Self, p: Pt(usize), v: T) void {
            self.data[p.x + p.y * self.width] = v;
        }

        pub fn neighbours4(self: Self, p: Pt(usize)) [4]?Pt(usize) {
            return p.neighbours4in(self.width, self.height);
        }

        pub fn neighbours8(self: Self, p: Pt(usize)) [8]?Pt(usize) {
            return p.neighbours8in(self.width, self.height);
        }

        pub fn coords(self: Self) CoordIterator {
            return CoordIterator{.width = self.width, .height = self.height};
        }

        pub fn format(self: Self, writer: *std.Io.Writer) !void {
            // we're going to be using this ~exclusively in `std.log.*` calls, which prefix with a level string
            // so may as well insert a newline
            try writer.print("\n", .{});
            for (self.data, 1..) |entry, i| {
                if (T == u8) {
                    try writer.print("{c}", .{entry});
                } else {
                    try writer.print("{any}", .{entry});
                }
                if (i % self.width == 0) {
                    try writer.print("\n", .{});
                }
            }
        }
    };
}

pub fn PaddedGrid(comptime T: type, comptime padding: usize) type {
    return struct {
        const Self = @This();

        data: []?T = undefined,
        width: usize = undefined,
        height: usize = undefined,
        // padding: usize,
        allocator: Allocator,

        pub fn init(allocator: Allocator, data: []T, width: usize) !Self {
            const height = data.len / width;
            var padded_data = try allocator.alloc(?T, (width + 2 * padding) * (height + 2 * padding));
            for (0..width + 2 * padding) |x| {
                for (0..height + 2 * padding) |y| {
                    // at the edges, insert a null
                    if (y == 0 or x == 0 or x == width + 2 * padding - 1 or y == height + 2 * padding - 1) {
                        padded_data[x + y * (width + 2 * padding)] = null;
                    } else {
                        padded_data[x + y * (width + 2 * padding)] = data[(x-padding) + (y-padding) * width];
                    }
                }
            }

            return .{
                .data = padded_data,
                .width = width + padding * 2,
                .height = height + padding * 2,
                // .padding = padding,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: Self) void {
            self.allocator.free(self.data);
        }

        pub fn containsi(self: Self, p: usize) bool {
            return (
                (p % (self.width) > 0) and
                (p / (self.width) > 0) and
                (p % (self.width) < self.width - 1) and
                (p / (self.width) < self.height - 1)
            );
        }

        pub fn at(self: Self, p: Pt(usize)) ?T {
            return self.at2(p.x, p.y);
        }
        // GRIPE: no operator overloading, no function overloading
        pub fn at2(self: Self, x: usize, y: usize) ?T {
            return self.data[x + y * self.width];
        }

        pub fn ati(self: Self, i: usize) ?T {
            return self.data[i];
        }

        pub fn set(self: *Self, p: Pt(usize), v: ?T) void {
            self.data[p.x + p.y * self.width] = v;
        }

        pub fn seti(self: *Self, i: usize, v: ?T) void {
            self.data[i] = v;
        }

        // pub fn neighbours4(self: Self, p: Pt(usize)) [4]?Pt(usize) {
        //     return p.neighbours4in(self.width, self.height);
        // }
        //
        // pub fn neighbours8(self: Self, p: Pt(usize)) [8]?Pt(usize) {
        //     return p.neighbours8in(self.width, self.height);
        // }

        pub fn neighbours4(self: Self, i: usize) [4]usize {
            assert(i % (self.width) > 0);
            assert(i / (self.width) > 0);
            assert(i % (self.width) <= self.width);
            assert(i / (self.width) <= self.height);
            return [4]usize{
                i - 1,  // x-1, y
                i + 1,  // x+1, y
                i - self.width,  // x, y-1
                i + self.width,  // x, y+1
            };
        }

        pub fn neighbours8(self: Self, i: usize) [8]usize {
            assert(i % (self.width) > 0);
            assert(i / (self.width) > 0);
            assert(i % (self.width) <= self.width);
            assert(i / (self.width) <= self.height);
            return [8]usize{
                i - 1,  // x-1, y
                i + 1,  // x+1, y
                i - self.width,  // x, y-1
                i + self.width,  // x, y+1
                i - 1 - self.width,  // x-1, y-1
                i + 1 - self.width,  // x+1, y-1
                i - 1 + self.width,  // x-1, y+1
                i + 1 + self.width,  // x+1, y+1
            };
        }

        pub fn coords(self: Self) PaddedCoordIterator {
            return PaddedCoordIterator{.width = self.width - 2 * padding, .height = self.height - 2 * padding, .padding = padding};
        }

        pub fn format(self: Self, writer: *std.Io.Writer) !void {
            // we're going to be using this ~exclusively in `std.log.*` calls, which prefix with a level string
            // so may as well insert a newline
            try writer.print("\n", .{});
            for (self.data, 1..) |entry, i| {
                if (T == u8) {
                    try writer.print("{c}", .{entry orelse ' '});
                } else {
                    try writer.print("{any}", .{entry});
                }
                if (i % (self.width) == 0) {
                    try writer.print("\n", .{});
                }
            }
        }
    };
}

const CoordIterator = struct {
    const Self = @This();

    width: usize,
    height: usize,
    x: usize = 0,
    y: usize = 0,

    // GRIPE: how can I say this doesn't care about the type param of grid??
    // pub fn init(grid: Grid) Self {
    //     return .{
    //         .width = grid.width,
    //         .height = grid.height,
    //     };
    // }

    pub fn next(self: *Self) ?Pt(usize) {
        if (self.x < self.width and self.y < self.height) {
            const oldx = self.x;
            const oldy = self.y;
            self.x += 1;
            if (self.x == self.width) {
                self.x = 0;
                self.y += 1;
            }
            return .{.x = oldx, .y = oldy};
        }
        return null;
    }
};

const PaddedCoordIterator = struct {
    const Self = @This();

    width: usize,
    height: usize,
    x: usize = 0,
    y: usize = 0,
    padding: usize,

    // GRIPE: how can I say this doesn't care about the type param of grid??
    // pub fn init(grid: Grid) Self {
    //     return .{
    //         .width = grid.width,
    //         .height = grid.height,
    //     };
    // }

    pub fn next(self: *Self) ?usize {
        if (self.x < self.width and self.y < self.height) {
            const oldx = self.x;
            const oldy = self.y;
            self.x += 1;
            if (self.x == self.width) {
                self.x = 0;
                self.y += 1;
            }
            // shift result into valid region of the grid
            return oldx + self.padding + (oldy + self.padding) * (self.padding * 2 + self.width);
        }
        return null;
    }
};