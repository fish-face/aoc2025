const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Queue = std.PriorityQueue;
const HashMap = std.AutoHashMap;
const findScalar = std.mem.findScalar;

const T = f64;
const Matrix = aoc.Matrix(T);

fn simplexMatrix(allocator: Allocator, prob: Problem) !T {
    const num_buttons = prob.p2buttons.len;
    const num_joltages = prob.p2target.len;
    var matrix = try Matrix.zeroes(
        allocator,
        num_buttons + 2,
        num_joltages + 1,
    );
    defer matrix.deinit();

    for (prob.p2target, 1..) |joltage, j| {
        matrix.set(j, 1 + num_buttons, @floatFromInt(joltage));
    }
    matrix.set(0, 0, 1);
    for (prob.p2buttons, 1..) |button, i| {
        matrix.set(0, i, 1);
        for (button, 0..) |btn_val, j| {
            _ = j;
            matrix.set(num_joltages - btn_val, i, 1.0);
        }
    }

    // var pivots = try allocator.alloc(usize, num_buttons);
    // std.log.debug("{f}", .{matrix});
    matrix.ge();
    // std.log.debug("{f}", .{matrix});
    const rank = matrix.rank();

    const matrix_data_copy = try allocator.alloc(T, matrix.data.len);
    defer allocator.free(matrix_data_copy);
    @memcpy(matrix_data_copy, matrix.data);
    const matrix_copy = Matrix.initBuffer(matrix_data_copy, matrix.cols);


    // const x = try allocator.alloc(T, num_joltages);
    var x = try List(T).initCapacity(allocator, num_joltages);
    solve(&x, matrix);
    // std.log.debug("solution: {any} min: {d}", .{x, std.mem.min});
    while (std.mem.min(T, x.items) < -1e-10) {
        // std.log.debug("infeasible, {any}", .{x});
        const row = std.mem.findMin(T, x.items);
        // + 1 due to row of costs at the top
        const col = std.mem.findMin(T, matrix.row(row + 1)[1.. matrix.cols - 1]);
        matrix.eliminate(row + 1, col + 1);
        // std.log.debug("eliminated {f}", .{matrix});
        solve(&x, matrix);
        // break;
    }
    // std.log.debug("basic feasible{f}", .{matrix});

    while (simplexStep(&matrix)) {
        // std.log.debug("simplex {f}", .{matrix});
    }

    // std.log.debug("{f}", .{matrix});
    // std.log.debug("cost? {d}", .{-matrix.at(0, matrix.cols - 1)});
    solve(&x, matrix);
    if (allInteger(x.items)) {
        // Simplex found an integer solution and we can return it
        // std.log.warn("exact {d}", .{-matrix.at(0, matrix.cols - 1)}) ;
        return -matrix.at(0, matrix.cols - 1);
    }
    return bruteForce(matrix_copy, rank);
}

const SEARCH_MAX: usize = 140;

fn bruteForce(m: Matrix, rank: usize) T {
    var free_vars = [_]usize{0, 0, 0};
    var free_vals = [_]T{0, 0, 0};
    const num_free = m.cols - rank - 2;

    var best: T = std.math.floatMax(T);

    var free_pos: usize = 0;
    var free_i: usize = 0;

    for (1..m.cols - 1) |c| {
        if (free_pos + 1 < m.rows and isBasicCol(m, free_pos + 1, c)) {
            // std.log.debug("basic @ {d},{d}", .{free_pos + 1, c});
            free_pos += 1;
        } else {
            // std.log.debug("nonbasic @ {d},{d}", .{free_pos + 1, c});
            free_vars[free_i] = c - 1;
            free_i += 1;
            if (free_i >= num_free) break;
        }
        // if (free_pos + 1 >= m.rows) {
        //     break;
        // }
    }

    // std.log.debug("brute forcing: {d}, {any}", .{num_free, free_vars});

    if (num_free == 1) {
        for (0..SEARCH_MAX) |x_| {
            const x: isize = @as(isize, @intCast(x_)) - 0;
            free_vals[0] = @floatFromInt(x);
            const cost = eval_cost(&m, free_vars[0..1], free_vals[0..1]);
            best = @min(
                best,
                cost,
            );
            // std.log.debug("cost: {d} best: {d}", .{cost, best});
        }
    } else if (num_free == 2) {
        for (0..SEARCH_MAX) |x_| {
            for (0..SEARCH_MAX) |y_| {
                const x: isize = @as(isize, @intCast(x_)) - 0;
                const y: isize = @as(isize, @intCast(y_)) - 0;
                free_vals[0] = @floatFromInt(x);
                free_vals[1] = @floatFromInt(y);
                const cost = eval_cost(&m, free_vars[0..2], free_vals[0..2]);
                best = @min(
                    best,
                    cost,
                );
                // std.log.debug("cost: {d} best: {d}", .{cost, best});
            }
        }
    } else if (num_free == 3) {
        for (0..SEARCH_MAX) |x_| {
            for (0..SEARCH_MAX) |y_| {
                for (0..SEARCH_MAX) |z_| {
                    const x: isize = @as(isize, @intCast(x_)) - 0;
                    const y: isize = @as(isize, @intCast(y_)) - 0;
                    const z: isize = @as(isize, @intCast(z_)) - 0;
                    free_vals[0] = @floatFromInt(x);
                    free_vals[1] = @floatFromInt(y);
                    free_vals[2] = @floatFromInt(z);
                    const cost = eval_cost(&m, free_vars[0..3], free_vals[0..3]);
                    best = @min(
                        best,
                        cost,
                    );
                    // std.log.debug("cost: {d} best: {d}", .{cost, best});
                }
            }
        }
    }

    // std.log.debug("rank {d} free {d}", .{rank, num_free});
    // std.log.warn("best: {d}", .{best});

    return best;
}

fn eval_cost(m: *const Matrix, free_vars: []const usize, free_vals: []const T) T {
    // Storage for multiplicand
    var x_ = [_]T{0} ** 50;
    var x = x_[0..m.cols - 2];

    // var i: usize = 0;
    // for (0..m.cols - 2) |c| {
    //     if (c == free_vars[i]) {
    //         x[c] = free_vals[i];
    //         i += 1;
    //         if (i >= free_vars.len) {
    //             break;
    //         }
    //     }
    // }
    for (free_vars, free_vals) |i, v| {
        x[i] = v;
    }

    // Storage for result of multiplying m by a candidate vector
    var out_ = [_]T{0} ** 50;
    // truncate to actual size of output (which is number of targets)
    var out = out_[0..m.rows - 1];

    // Evaluate target - m * x and put result into out:
    for (0..m.rows - 1) |r| {
        // +1 to skip top row of costs
        const row = m.row(r + 1);
        out[r] = row[row.len - 1];
        // std.log.debug("{any}", .{row[1..row.len - 1]});
        for (row[1..row.len - 1], 0..) |entry, c| {
            // no +1 because this is exactly sized
            // std.log.debug("{d},{d} = {d}*{d}", .{r, c, entry, x[c]});
            out[r] -= entry * x[c];
        }
    }

    // std.log.warn("m: {f}", .{m});
    // std.log.debug("free: {any}", .{free_vars});
    // std.log.debug("free: {any}", .{free_vals});
    // std.log.debug("x: {any}", .{x});
    // std.log.debug("out: {any}", .{out});

    if (!allInteger(out) or !allNonNeg(out)) {
        return std.math.floatMax(T);
    }
    // The value in out is how much to "adjust" the target col in the augmented matrix
    // to use for the values of the basic variables. Since the cost of a solution is
    // the sum of the values of all variables, we just sum the target col (as normal),
    // add the sum of out, then add the sum of the free vars.

    var res: T = 0;
    for (out) |v| {
        res += v;
    }
    for (free_vals) |v| {
        res += v;
    }
    // for (1..m.rows) |r| {
    //     res += m.at(r, m.cols - 1);
    // }

    // std.log.warn("cost: {d}", .{res});

    return res;
}

test "eval basic" {
    var data = [_]T{
        1, 0, 0, 0,  1,  0,
        0, 1, 0, 0,  1,  6,
        0, 0, 1, 0, -1, -1,
        0, 0, 0, 1,  0,  5,
        0, 0, 0, 0,  0,  0,
        0, 0, 0, 0,  0,  0,
        0, 0, 0, 0,  0,  0
    };
    const m = Matrix.initBuffer(&data, 6);
    // const cost = eval_cost(&m, ([_]usize{3})[0..1], ([_]T{1})[0..1]);
    try std.testing.expectEqual(
        eval_cost(&m, ([_]usize{3})[0..1], ([_]T{1})[0..1]),
        11
    );
    try std.testing.expectEqual(
        eval_cost(&m, ([_]usize{3})[0..1], ([_]T{2})[0..1]),
        12
    );
    try std.testing.expectEqual(
        eval_cost(&m, ([_]usize{3})[0..1], ([_]T{3})[0..1]),
        13
    );
}

// const NTuplesIterator = struct {
//     n: usize,
//     cur: []T,
//     sum: T,
//     child: ?NTuplesIterator,
//     i: usize = 0,
//
//     fn init(allocator: Allocator, state: []T) @This() {
//
//         return .{
//             .n = state.len,
//             .cur = state,
//             .sum = 0,
//             .child = if (state.len > 2) @This().init(state[1..]) else null,
//         };
//     }
//
//     fn next(self: *@This()) []T {
//         if (self.cur[self.i] == self.max) {
//             if (self.i == self.n - 1) {
//                 self.max += 1;
//             } else {
//                 self.cur[self.i] = 0;
//             }
//         } else {
//             self.cur[self.i] += 1;
//         }
//
//         if (self.i == self.n - 1) {
//             self.i = 0;
//         } else {
//             self.i += 1;
//         }
//         return self.cur;
//     }
//
//     fn step(self: *@This()) void {
//         self.cur[0] = self.i;
//         self.cur[1] = self.sum - self.i;
//     }
// };

fn solve(x: *List(T), m: Matrix) void {
    x.clearRetainingCapacity();
    for (1..m.rows) |r| {
        x.appendAssumeCapacity(m.at(r, m.cols - 1));
    }
}

fn allInteger(x: []T) bool {
    for (x) |val| {
        if (@abs(@mod(val, 1)) > EPS and 1 - @abs(@mod(val, 1)) > EPS) {
            return false;
        }
    }

    return true;
}

fn allNonNeg(x: []T) bool {
    for (x) |val| {
        if (val + EPS < 0.0) {
            return false;
        }
    }

    return true;
}

const EPS = 0.000000001;

fn close(x: T, y: T) bool {
    return @abs(x - y) < EPS;
}

fn isBasicCol(m: Matrix, r: usize, c: usize) bool {
    if (!close(m.at(r, c), 1.0)) {
        return false;
    }
    for (0..m.rows) |rr| {
        if (r != rr and !close(m.at(rr, c), 0.0)) {
            return false;
        }
    }
    return true;
}

// fn combinations(m: usize, n: usize)
fn simplexStep(m: *Matrix) bool {
    // Find entering and departing variables (col and row, resp.)
    const entering = std.mem.findMin(T, m.row(0)[1 .. m.cols - 1]) + 1;
    // std.log.debug("e: {d}", .{entering});
    var lowest_val = std.math.floatMax(T);
    var departing: ?usize = null;
    for (1..m.rows) |i| {
        const target = m.at(i, m.cols - 1);
        const divisor = m.at(i, entering);
        if (divisor > EPS) {
            const val = target / divisor;
            if (val < lowest_val) {
                lowest_val = val;
                departing = i;
            }
        }
    }
    if (departing == null or isBasicCol(m.*, departing.?, entering)) {
        // std.log.debug("finished", .{});
        return false;
    }
    // std.log.debug("e: {d} d: {d}", .{entering, departing.?});
    m.eliminate(departing.?, entering);
    return true;
}

const Problem = struct {
    p1target: u16,
    p1buttons: []u16,
    p2target: []u16,
    p2buttons: [][]u16,
};

fn parse(allocator: Allocator, line: []const u8) !Problem {
    var p = findScalar(u8, line, ']').?;
    const p1target_s = line[1..p];
    var p1target: u16 = 0;
    for (p1target_s) |c| {
        p1target <<= 1;
        if (c == '#') {
            p1target |= 1;
        }
    }

    var p1buttons = try List(u16).initCapacity(allocator, 16);
    var p2buttons = try List([]u16).initCapacity(allocator, 16);

    var button_start = p;

    while (true) {
        const c = line[p];
        switch (c) {
            '{' => {
                break;
            },
            '(' => {
                button_start = p + 1;
            },
            ')' => {
                const button = line[button_start..p];
                var p2button = try List(u16).initCapacity(allocator, 12);
                const p1button = parseButton(allocator, &p2button, button, @intCast(p1target_s.len));

                p1buttons.appendAssumeCapacity(p1button);
                // hahahaha it's AoC we just leak it
                p2buttons.appendAssumeCapacity(p2button.items);
            },
            else => {},
        }
        p += 1;
    }

    const ctxt = struct {
        items: []u16,
        pub fn lessThan(self: @This(), a: usize, b: usize) bool {
            return @popCount(self.items[a]) > @popCount(self.items[b]);
        }
        pub fn swap(self: @This(), a: usize, b: usize) void {
            std.mem.swap(u16, &self.items[a], &self.items[b]);
        }
    }{
        .items = p1buttons.items,
    };
    std.mem.sortUnstableContext(0, p1buttons.items.len, ctxt);

    const p2target_s = line[p..];
    // leak it all
    const p2target = try allocator.alloc(u16, 12);
    const count = aoc.parse.parseInts(u16, p2target, p2target_s, ',');

    return .{
        .p1target = p1target,
        .p1buttons = p1buttons.items,
        .p2target = p2target[0..count],
        .p2buttons = p2buttons.items,
    };
}

fn parseP1Button(button_s: []const u8, digits: u4) u16 {
    var res: u16 = 0;
    var nums = std.mem.tokenizeScalar(u8, button_s, ',');
    while (nums.next()) |num| {
        const n = aoc.parse.atoi(u4, num);
        const one: u16 = 1;
        res |= one << (digits - n - 1);
    }

    return res;
}

fn parseButton(allocator: Allocator, part2: *List(u16), button_s: []const u8, digits: u4) u16 {
    _ = allocator;
    var part1: u16 = 0;
    var nums = std.mem.tokenizeScalar(u8, button_s, ',');
    while (nums.next()) |num| {
        const n = aoc.parse.atoi(u4, num);
        const one: u16 = 1;
        part1 |= one << (digits - n - 1);
        part2.appendAssumeCapacity(digits - n - 1);
    }

    return part1;
}

const P1State = struct {
    presses: usize,
    state: u16,

    pub fn compareFn(_: void, a: @This(), b: @This()) std.math.Order {
        return std.math.order(a.presses, b.presses);
    }
};

fn p1search(allocator: Allocator, target: u16, buttons: []const u16) !usize {
    var queue = Queue(P1State, void, P1State.compareFn).init(allocator, {});
    try queue.add(.{ .presses = 0, .state = 0 });

    var seen = HashMap(u16, void).init(allocator);

    while (queue.removeOrNull()) |current| {
        if (current.state == target) {
            return current.presses;
        }
        if (seen.contains(current.state)) {
            continue;
        }
        try seen.put(current.state, {});

        for (buttons) |button| {
            const next_state = current.state ^ button;
            try queue.add(.{ .presses = current.presses + 1, .state = next_state });
        }
    }

    return 0;
}

const P2State = struct {
    presses: usize,
    state: []const u16,

    pub fn compareFn(_: void, a: @This(), b: @This()) std.math.Order {
        if (a.presses < b.presses) return .lt;
        if (a.presses > b.presses) return .gt;
        if (std.mem.lessThan(u16, a.state, b.state)) return .gt;
        if (std.mem.lessThan(u16, b.state, a.state)) return .lt;
        return .eq;
    }

    pub fn add(out: *@This(), a: @This(), b: @This()) void {
        out.presses = a.presses + b.presses;
        for (a.state, 0..) |as, i| {
            out.state[i] = as + b.state[i];
        }
    }
};

const SliceHasher = struct {
    pub fn hash(_: SliceHasher, key: []const u16) u64 {
        var hasher = std.hash.Wyhash.init(0);
        std.hash.autoHashStrat(&hasher, key, .Deep);
        return hasher.final();
    }

    pub fn eql(_: SliceHasher, a: []const u16, b: []const u16) bool {
        return std.mem.eql(u16, a, b);
    }
    // pub const hash = std.hash.autoHashStrat(P2State, @This(), .Deep);
    // pub const hash = std.hash.autoHashStrat(std.hash.Wyhash, @This(), .Deep);
};

fn p2search(allocator: Allocator, target: []u16, buttons: []const u16) !usize {
    const len = target.len;
    var start = try allocator.alloc(u16, len);
    defer allocator.free(start);

    for (0..len) |i| {
        start[i] = 0;
    }
    var queue = Queue(P2State, void, P2State.compareFn).init(allocator, {});
    defer queue.deinit();
    try queue.add(.{ .presses = 0, .state = start });

    var kill = std.HashMap([]const u16, void, SliceHasher, 80).init(allocator);
    defer kill.deinit();
    var best = std.HashMap([]const u16, usize, SliceHasher, 80).init(allocator);
    defer best.deinit();
    try best.put(start, 0);
    // GRIPE: can't automatically hash slices
    // UNGRIPE: the error message is clear
    // GRIPE: meaning of "max_load_percentage" is totally unclear. Does 80 = 80%? Why then is it a u64?
    // var seen = std.HashMap(
    //     []const u16, void, SliceHasher, 80
    // ).init(allocator);

    while (queue.removeOrNull()) |current| {
        std.log.debug("{any}", .{current});
        // GRIPE no == for slices
        if (std.mem.eql(u16, current.state, target)) {
            return current.presses;
        }
        // if (seen.contains(current.state)) {
        //     continue;
        // }
        // try seen.put(current.state, {});

        // var added_moves = try List([]const u16).initCapacity(allocator, buttons.len);
        // defer added_moves.deinit(allocator);

        outer: for (buttons, 0..) |button, btn_i| {
            _ = btn_i;
            var next_state = try allocator.alloc(u16, len);
            std.mem.copyForwards(u16, next_state, current.state);
            for (0..len) |i| {
                const one: u16 = 1;
                if (button & (one << @intCast(len - i - 1)) > 0) {
                    next_state[i] += 1;
                    if (next_state[i] > target[i]) {
                        allocator.free(next_state);
                        continue :outer;
                    }
                }
            }
            // std.log.debug("move: {any}", .{next_state});
            // if (btn_i > 0) {
            //     // see whether there's any point pressing this button
            //     var could_be_better = false;
            //     kill: for (added_moves.items) |competing_state| {
            //         // if competing state >= next_state, skip
            //         for (0..len) |i| {
            //             if (next_state[i] > competing_state[i]) {
            //                 could_be_better = true;
            //                 // std.log.debug("better than: {any}", .{competing_state});
            //                 break :kill;
            //             }
            //         }
            //         // std.log.debug("worse than: {any}", .{competing_state});
            //     }
            //     if (!could_be_better) continue;
            // }
            // added_moves.appendAssumeCapacity(next_state);

            const next_presses = current.presses + 1;
            const next = P2State{ .presses = next_presses, .state = next_state };
            // for (buttons, 0..) |other_button, btn_j| {
            //     if (btn_i == btn_j) continue;
            //
            // }
            if (best.get(next_state)) |old_presses| {
                if (old_presses > next_presses) {
                    const old = P2State{ .presses = old_presses, .state = next_state };
                    try best.put(next_state, next_presses);
                    queue.update(old, next) catch {
                        try queue.add(next);
                    };
                }
            } else {
                try best.put(next_state, next_presses);
                try queue.add(next);
            }
        }
        // allocator.free(current.state);
    }

    std.log.warn("failed", .{});
    return 0;
}

pub fn main() !void {
    const allocator = try aoc.allocator();

    const reader = try aoc.Reader.init(allocator);

    var p1: usize = 0;
    var p2: usize = 0;

    for (0..1) |repeat| {
        var lines = try reader.iterLines();
        while (lines.next()) |line| {
            const problem = try parse(allocator, line);
            // std.log.debug("{any}", .{problem});
            p1 += try p1search(allocator, problem.p1target, problem.p1buttons);
            // p2 += try p2search(allocator, problem.p2target, problem.p1buttons);
            p2 += @intFromFloat(std.math.round(try simplexMatrix(allocator, problem)));
        }
        p1 += 0;
        p2 += 0;
        if (repeat == 0) {
            try aoc.print("{d}\n{d}\n", .{ p1, p2 });
        }
    }
}
