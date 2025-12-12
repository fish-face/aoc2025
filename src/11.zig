const std = @import("std");
const aoc = @import("aoc");
const Allocator = std.mem.Allocator;

const Graph = std.StringHashMap(Node);

const Node = struct {
    label: []const u8,
    allocator: Allocator,
    // TODO it is almost certainly better to store *Node everywhere. We are eating dereferencing cost anyway, so may as
    //      well pass around 1 ptr not 3.
    adjacent: *std.ArrayList(Node),

    fn init(allocator: Allocator, label: []const u8) !@This() {
        const label_ = try allocator.alloc(u8, 3);
        std.mem.copyForwards(u8, label_, label);
        const adjacent = try allocator.create(std.ArrayList(Node));
        adjacent.* = .{};
        return .{
            .label = label_,
            .allocator = allocator,
            .adjacent = adjacent,
        };
    }

    fn deinit(self: @This()) void {
        self.allocator.free(self.label);
        self.adjacent.deinit(self.allocator);
        self.allocator.destroy(self.adjacent);
    }

    fn add(self: *Node, other: Node) !void {
        return self.adjacent.append(self.allocator, other);
    }

    pub fn format(self: @This(), writer: *std.Io.Writer) !void {
        try writer.print("{s}: [", .{self.label});
        for (self.adjacent.items) |adj| {
            try writer.print("{s} ", .{adj.label});
        }
        try writer.print("]", .{});
    }
};

fn search2(allocator: Allocator, toponodes: std.ArrayList(Node), start: Node, target: []const u8) !usize {
    var paths_to = std.StringHashMap(usize).init(allocator);
    defer paths_to.deinit();

    for (toponodes.items) |node| {
        try paths_to.put(node.label, 0);
    }
    try paths_to.put(start.label, 1);

    for (toponodes.items) |node| {
        const paths = paths_to.get(node.label) orelse 0;
        for (node.adjacent.items) |neighbour| {
            paths_to.getPtr(neighbour.label).?.* += paths;
        }
    }

    return paths_to.get(target).?;
}

fn toposort(allocator: Allocator, result: *std.ArrayList(Node), start: Node) !void {
    var seen = std.StringHashMap(void).init(allocator);
    defer seen.deinit();

    try dfs(allocator, &seen, result, start);
    std.mem.reverse(Node, result.items);
}

fn dfs(allocator: Allocator, seen: *std.StringHashMap(void), sorted_nodes: *std.ArrayList(Node), node: Node) !void {
    if (seen.get(node.label) != null) {
        return;
    }

    for (node.adjacent.items) |neighbour| {
        try dfs(allocator, seen, sorted_nodes, neighbour);
    }

    try seen.put(node.label, {});
    try sorted_nodes.append(allocator, node);
}

pub fn main() !void {
    const allocator = try aoc.fixed_allocator();

    const reader = try aoc.Reader.init(allocator);

    var p1: usize = 0;
    var p2: usize = 0;

    for (0..aoc.build_options.repeats) |repeat| {
        var lines = try reader.iterLines();
        var nodes = Graph.init(allocator);
        try nodes.ensureTotalCapacity(1024);

        while (lines.next()) |line| {
            var node: Node = nodes.get(line[0..3]) orelse try Node.init(allocator, line[0..3]);
            nodes.putAssumeCapacity(node.label, node);
            var labels = std.mem.tokenizeScalar(u8, line[5..], ' ');

            while (labels.next()) |label| {
                if (nodes.get(label)) |node2| {
                    try node.add(node2);
                } else {
                    const node2 = try Node.init(allocator, label);

                    try node.add(node2);
                    nodes.putAssumeCapacity(node2.label, node2);
                }
            }
        }

        {
            var toponodes = try std.ArrayList(Node).initCapacity(allocator, nodes.count());
            defer toponodes.deinit(allocator);
            try toposort(allocator, &toponodes, nodes.get("you").?);
            p1 = try search2(allocator, toponodes, nodes.get("you").?, "out");
        }
        if (nodes.get("svr") != null) {
            var toponodes = try std.ArrayList(Node).initCapacity(allocator, nodes.count());
            defer toponodes.deinit(allocator);
            try toposort(allocator, &toponodes, nodes.get("svr").?);

            const svr_to_fft = try search2(allocator, toponodes, nodes.get("svr").?, "fft");
            const svr_to_dac = try search2(allocator, toponodes, nodes.get("svr").?, "dac");
            const fft_to_dac = try search2(allocator, toponodes, nodes.get("fft").?, "dac");
            const dac_to_fft = try search2(allocator, toponodes, nodes.get("dac").?, "fft");
            const fft_to_out = try search2(allocator, toponodes, nodes.get("fft").?, "out");
            const dac_to_out = try search2(allocator, toponodes, nodes.get("dac").?, "out");
            p2 = svr_to_fft * fft_to_dac * dac_to_out + svr_to_dac * dac_to_fft * fft_to_out;
        }
        if (repeat == 0) {
            try aoc.print("{d}\n{d}\n", .{p1, p2});
        }

        if (aoc.build_options.repeats > 1) {
            var iter = nodes.iterator();
            while (iter.next()) |node| {
                node.value_ptr.deinit();
            }
            nodes.deinit();
        }
    }
}
