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
