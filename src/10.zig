const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Queue = std.PriorityQueue;
const HashMap = std.AutoHashMap;
const findScalar = std.mem.findScalar;

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

    for (0..aoc.build_options.repeats) |repeat| {
        var lines = try reader.iterLines();
        while (lines.next()) |line| {
            const problem = try parse(allocator, line);
            std.log.debug("{any}", .{problem});
            p1 += try p1search(allocator, problem.p1target, problem.p1buttons);
            p2 += try p2search(allocator, problem.p2target, problem.p1buttons);
        }
        p1 += 0;
        p2 += 0;
        if (repeat == 0) {
            try aoc.print("{d}\n{d}\n", .{ p1, p2 });
        }
    }
}
