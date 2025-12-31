const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn Matrix(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: Allocator,
        data: []T = undefined,
        cols: usize = undefined,
        rows: usize = undefined,

        pub fn initBuffer(data: []T, cols: usize) Self {
            return .{
                .allocator = undefined,
                .data = data,
                .cols = cols,
                .rows = data.len / cols,
            };
        }

        pub fn zeroes(allocator: Allocator, cols: usize, rows: usize) !Self {
            const data = try allocator.alloc(T, rows * cols);
            @memset(data, 0);
            return .{
                .allocator = allocator,
                .data = data,
                .cols = cols,
                .rows = rows,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.data);
        }

        pub fn at(self: Self, r: usize, c: usize) T {
            return self.data[r * self.cols + c];
        }

        pub fn atr(self: Self, r: usize, c: usize) *T {
            return &self.data[r * self.cols + c];
        }

        pub fn set(self: *Self, r: usize, c: usize, val: T) void {
            self.data[r * self.cols + c] = val;
        }

        pub fn row(self: *const Self, i: usize) []T {
            return self.data[i * self.cols .. (i + 1) * self.cols];
        }

        pub fn swapRows(self: *Self, i: usize, j: usize) void {
            var row_a = self.row(i);
            var row_b = self.row(j);
            for (0..self.cols) |y| {
                const tmp = row_a[y];
                row_a[y] = row_b[y];
                row_b[y] = tmp;
            }
        }

        /// add src row to dst row
        pub fn addRow(self: *Self, dst: usize, src: usize) void {
            self.mulAddRow(dst, src, 1);
        }

        /// add src row to dst row
        pub fn mulAddRow(self: *Self, dst: usize, src: usize, x: T) void {
            const row_src = self.row(src);
            var row_dst = self.row(dst);
            for (0..self.cols) |y| {
                row_dst[y] += x * row_src[y];
            }
        }

        /// scale row by a constant factor
        pub fn scaleRow(self: *Self, r: usize, x: T) void {
            for (0..self.cols) |j| {
                self.atr(r, j).* *= x;
            }
        }

        /// gaussian elimination
        pub fn ge(self: *Self) void {
            var r: usize = 0;
            // var c: usize = 0;

            ////
            // WARNING
            // EXTREME HACK: skip the final column on the assumption
            // that it's part of an augmented matrix that we don't want to
            // eliminate
            ////
            for (0..self.cols - 1) |c| {
                // find a non-zero entry
                // std.log.warn("row {d} col {d}", .{r, c});
                for (r..self.rows) |rr| {
                    if (self.at(rr, c) != 0) {
                        // std.log.warn("found non-zero entry in row {d}", .{rr});
                        if (r != rr) {
                            self.swapRows(rr, r);
                        }
                        self.eliminate(r, c);
                        r += 1;
                        break;
                    }
                }
                // std.log.warn("{f}", .{self});
            }
        }

        pub fn eliminate(self: *Self, r: usize, c: usize) void {
            // get 1 in current entry
            // std.log.warn("scaling", .{});
            // std.log.warn("{f}", .{self});
            self.scaleRow(r, @as(T, 1) / self.at(r, c));
            // std.log.warn("{f}", .{self});
            // get 0 elsewhere in current column
            for (0..self.rows) |rr| {
                if (rr == r) continue;
                self.mulAddRow(rr, r, -self.at(rr, c));
            }
        }

        /// Compute rank assuming the matrix is in reduced-row echelon form
        pub fn rank(self: Self) usize {
            var res: usize = 0;
            for (1..self.rows) |r| {
                for (1..self.cols - 1) |c| {
                    switch (@typeInfo(T)) {
                        .float => {
                            if (@abs(self.at(r, c)) > 1e-10) {
                                res += 1;
                                break;
                            }
                        },
                        .int => {
                            if (self.at(r, c) != 0) {
                                res += 1;
                                break;
                            }
                        },
                        else => {
                            @panic("unsupported type");
                        }
                    }
                }
            }

            return res;
        }
        pub fn format(self: Self, writer: *std.Io.Writer) !void {
            // we're going to be using this ~exclusively in `std.log.*` calls, which prefix with a level string
            // so may as well insert a newline
            try writer.print("\n", .{});
            for (self.data, 1..) |entry, i| {
                try writer.print("{any} ", .{entry});
                if (i % self.cols == 0) {
                    try writer.print("\n", .{});
                }
            }
        }
    };
}

test "test swap rows" {
    var data = [_]i32{ 1, 2, 3, 4 };
    const swapped = [_]i32{
        3, 4,
        1, 2,
    };
    var m = Matrix(i32).initBuffer(&data, 2);
    m.swapRows(0, 1);
    try std.testing.expect(std.mem.eql(i32, m.data, &swapped));
}

test "test add rows" {
    var data = [_]i32{ 1, 2, 3, 4 };
    const added = [_]i32{
        4, 6,
        3, 4,
    };
    var m = Matrix(i32).initBuffer(&data, 2);
    m.addRow(0, 1);
    try std.testing.expect(std.mem.eql(i32, m.data, &added));
}

test "test scale row" {
    var data = [_]i32{ 1, 2, 3, 4 };
    const scaled = [_]i32{
        1, 2,
        6, 8,
    };
    var m = Matrix(i32).initBuffer(&data, 2);
    m.scaleRow(1, 2);
    try std.testing.expect(std.mem.eql(i32, m.data, &scaled));
}

test "gaussian elimination" {
    var data = [_]f32{ 1, 2, 3, 4 };
    const eliminated = [_]f32{
        1, 0,
        0, 1,
    };
    var m = Matrix(f32).initBuffer(&data, 2);
    m.ge();
    try std.testing.expect(std.mem.eql(f32, m.data, &eliminated));
}

test "gaussian elimination singular" {
    var data = [_]f32{
        2,  1,  -1, 8,
        -3, -1, 2,  -11,
        -2, 1,  2,  -3,
    };
    const eliminated = [_]f32{
        1, 0, 0, 2,
        0, 1, 0, 3,
        0, 0, 1, -1,
    };
    var m = Matrix(f32).initBuffer(&data, 4);
    m.ge();
    try std.testing.expect(std.mem.eql(f32, m.data, &eliminated));
}
