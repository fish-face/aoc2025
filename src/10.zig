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
    // p2target: []u16,
    // p2buttons: [][]u16,
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
    // var p2buttons = try List(List(u16)).initCapacity(allocator, 10);

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
                p1buttons.appendAssumeCapacity(parseP1Button(button, @intCast(p1target_s.len)));
                // p2buttons.appendAssumeCapacity(parseP2Button(button));
            },
            else => {},
        }
        p += 1;
    }

    return .{
        .p1target = p1target,
        .p1buttons = p1buttons.items,
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

const P1State = struct {
    presses: usize,
    state: u16,

    pub fn compareFn (_: void, a: @This(), b: @This()) std.math.Order {
        return std.math.order(a.presses, b.presses);
    }
};

fn p1search(allocator: Allocator, target: u16, buttons: []const u16) !usize {
    var queue = Queue(P1State, void, P1State.compareFn).init(allocator, {});
    try queue.add(.{.presses = 0, .state = 0});

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
            try queue.add(.{.presses = current.presses + 1, .state = next_state});
        }
    }

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
            // std.log.debug("{any}", .{problem});
            p1 += try p1search(allocator, problem.p1target, problem.p1buttons);
        }
        p1 += 0;
        p2 += 0;
        if (repeat == 0) {
            try aoc.print("{d}\n{d}\n", .{p1, p2});
        }
    }
}
