const std = @import("std");
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