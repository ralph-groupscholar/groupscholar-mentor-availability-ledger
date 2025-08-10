const std = @import("std");

pub fn isIsoDate(value: []const u8) bool {
    if (value.len != 10) return false;
    if (value[4] != '-' or value[7] != '-') return false;
    return isDigitSlice(value[0..4]) and isDigitSlice(value[5..7]) and isDigitSlice(value[8..10]);
}

pub fn isIsoTimestamp(value: []const u8) bool {
    if (value.len != 19) return false;
    if (value[4] != '-' or value[7] != '-' or value[10] != 'T' or value[13] != ':' or value[16] != ':') return false;
    return isDigitSlice(value[0..4]) and isDigitSlice(value[5..7]) and isDigitSlice(value[8..10]) and
        isDigitSlice(value[11..13]) and isDigitSlice(value[14..16]) and isDigitSlice(value[17..19]);
}

pub fn isChronological(start: []const u8, end: []const u8) bool {
    return std.mem.order(u8, start, end) == .lt;
}

fn isDigitSlice(value: []const u8) bool {
    for (value) |ch| {
        if (ch < '0' or ch > '9') return false;
    }
    return true;
}

test "isIsoDate" {
    try std.testing.expect(isIsoDate("2026-02-08"));
    try std.testing.expect(!isIsoDate("2026-2-08"));
    try std.testing.expect(!isIsoDate("2026/02/08"));
}

test "isIsoTimestamp" {
    try std.testing.expect(isIsoTimestamp("2026-02-08T09:30:00"));
    try std.testing.expect(!isIsoTimestamp("2026-02-08 09:30:00"));
    try std.testing.expect(!isIsoTimestamp("2026-02-08T09:30"));
}

test "isChronological" {
    try std.testing.expect(isChronological("2026-02-08T09:00:00", "2026-02-08T10:00:00"));
    try std.testing.expect(!isChronological("2026-02-08T10:00:00", "2026-02-08T10:00:00"));
    try std.testing.expect(!isChronological("2026-02-08T11:00:00", "2026-02-08T10:00:00"));
}
