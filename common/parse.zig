const std = @import("std");


/// parse the integer in s, which is assumed to consist entirely of digits
pub fn atoi(comptime T: type, s: []const u8) T {
    var acc: T = 0;
    for (s) |digit| {
        acc *= 10;
        acc += digit - '0';
    }
    return acc;
}

/// parse the integer in s, but ignore non-digit chars
pub fn atoi_stripped(comptime T: type, s: []const u8) T {
    var acc: T = 0;
    for (s) |digit| {
        if (digit < '0' or digit > '9') continue;
        acc *= 10;
        acc += digit - '0';
    }
    return acc;
}

pub fn parseInts(comptime T: type, out: []T, s: []const u8, comptime delim: u8) usize {
    var count: usize = 0;
    var iterator = std.mem.tokenizeScalar(u8, s, delim);
    while (iterator.next()) |item| {
        out[count] = atoi_stripped(T, item);
        count += 1;
    }

    return count;
}