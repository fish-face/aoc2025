const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;

const N_PRESENTS: usize = 6;

fn countBlock(lines: anytype, present: *usize) void {
    _ = lines.*.next(); // skip number
    for (0..3) |i| {
        _ = i;
        const line = lines.*.next().?;
        for (0..3) |j| {
            if (line[j] == '#') {
                present.* += 1;
            }
        }
    }
}

const Problem = struct {
    w: usize,
    h: usize,
    requirements: [N_PRESENTS]usize,

    fn fromLine(line: []const u8) Problem {
        const w = aoc.parse.atoi(usize, line[0..2]);
        const h = aoc.parse.atoi(usize, line[3..5]);
        var requirements = [_]usize{undefined} ** N_PRESENTS;
        for (0..N_PRESENTS) |i| {
            requirements[i] = aoc.parse.atoi(usize, line[7+3*i..9+3*i]);
        }
        return .{
            .w = w,
            .h = h,
            .requirements = requirements,
        };
    }
};

pub fn main() !void {
    const allocator = try aoc.fixed_allocator();

    const reader = try aoc.Reader.init(allocator);

    var p1: usize = 0;

    for (0..aoc.build_options.repeats) |repeat| {
        var lines = try reader.iterLines();
        var presents = [_]usize{0} ** N_PRESENTS;
        var problems = try std.ArrayList(Problem).initCapacity(allocator, 1024);
        for (0..N_PRESENTS) |p| {
            countBlock(&lines, &presents[p]);
        }
        while (lines.next()) |line| {
            problems.appendAssumeCapacity(Problem.fromLine(line));
        }

        for (problems.items) |problem| {
            var total_requirement: usize = 0;
            for (0..N_PRESENTS) |i| {
                total_requirement += problem.requirements[i] * presents[i];
            }
            if (total_requirement <= problem.w * problem.h) {
                p1 += 1;
            }
        }

        if (repeat == 0) {
            try aoc.print("{d}\n", .{p1});
        }
    }
}
