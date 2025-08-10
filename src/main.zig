const std = @import("std");
const db = @import("db.zig");
const sql = @import("sql.zig");
const validation = @import("validation.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const stdout = std.io.getStdOut().writer();

    if (args.len < 2 or isHelp(args[1])) {
        try printUsage(stdout);
        return;
    }

    var conn = try db.Db.connect(allocator);
    defer conn.deinit();

    const command = args[1];
    if (std.mem.eql(u8, command, "mentor")) {
        if (args.len < 3 or isHelp(args[2])) {
            try printMentorUsage(stdout);
            return;
        }
        const action = args[2];
        if (std.mem.eql(u8, action, "list")) {
            try mentorList(&conn, allocator, stdout);
        } else if (std.mem.eql(u8, action, "add")) {
            try mentorAdd(&conn, allocator, args, stdout);
        } else {
            try printMentorUsage(stdout);
        }
    } else if (std.mem.eql(u8, command, "availability")) {
        if (args.len < 3 or isHelp(args[2])) {
            try printAvailabilityUsage(stdout);
            return;
        }
        const action = args[2];
        if (std.mem.eql(u8, action, "add")) {
            try availabilityAdd(&conn, allocator, args, stdout);
        } else if (std.mem.eql(u8, action, "list")) {
            try availabilityList(&conn, allocator, args, stdout);
        } else {
            try printAvailabilityUsage(stdout);
        }
    } else if (std.mem.eql(u8, command, "booking")) {
        if (args.len < 3 or isHelp(args[2])) {
            try printBookingUsage(stdout);
            return;
        }
        const action = args[2];
        if (std.mem.eql(u8, action, "add")) {
            try bookingAdd(&conn, allocator, args, stdout);
        } else if (std.mem.eql(u8, action, "list")) {
            try bookingList(&conn, allocator, args, stdout);
        } else {
            try printBookingUsage(stdout);
        }
    } else if (std.mem.eql(u8, command, "capacity")) {
        if (args.len < 3 or isHelp(args[2])) {
            try printCapacityUsage(stdout);
            return;
        }
        const action = args[2];
        if (std.mem.eql(u8, action, "range")) {
            try capacityRange(&conn, allocator, args, stdout);
        } else {
            try printCapacityUsage(stdout);
        }
    } else if (std.mem.eql(u8, command, "utilization")) {
        if (args.len < 3 or isHelp(args[2])) {
            try printUtilizationUsage(stdout);
            return;
        }
        const action = args[2];
        if (std.mem.eql(u8, action, "range")) {
            try utilizationRange(&conn, allocator, args, stdout);
        } else {
            try printUtilizationUsage(stdout);
        }
    } else {
        try printUsage(stdout);
    }
}

fn isHelp(value: []const u8) bool {
    return std.mem.eql(u8, value, "--help") or std.mem.eql(u8, value, "-h") or std.mem.eql(u8, value, "help");
}

fn getFlag(args: [][]const u8, flag: []const u8) ?[]const u8 {
    if (args.len < 2) return null;
    var idx: usize = 0;
    while (idx + 1 < args.len) : (idx += 1) {
        if (std.mem.eql(u8, args[idx], flag)) {
            return args[idx + 1];
        }
    }
    return null;
}

fn requireFlag(args: [][]const u8, flag: []const u8) ![]const u8 {
    return getFlag(args, flag) orelse error.MissingArgument;
}

fn normalizeTimestamp(allocator: std.mem.Allocator, value: []const u8) ![]const u8 {
    if (validation.isIsoTimestamp(value)) {
        return allocator.dupe(u8, value);
    }
    if (validation.isIsoDate(value)) {
        var buf = try allocator.alloc(u8, value.len + 9);
        std.mem.copyForwards(u8, buf[0..value.len], value);
        std.mem.copyForwards(u8, buf[value.len..], "T00:00:00");
        return buf;
    }
    return error.InvalidTimestamp;
}

fn ensureChronological(start: []const u8, end: []const u8) !void {
    if (!validation.isChronological(start, end)) {
        return error.InvalidRange;
    }
}

fn toPgTextArray(allocator: std.mem.Allocator, raw: []const u8) ![]const u8 {
    if (raw.len == 0) return allocator.dupe(u8, "{}");
    var parts = std.mem.splitSequence(u8, raw, ",");
    var list = std.ArrayList(u8).init(allocator);
    errdefer list.deinit();

    try list.append('{');
    var first = true;
    while (parts.next()) |part_raw| {
        const part = std.mem.trim(u8, part_raw, " ");
        if (part.len == 0) continue;
        if (!first) try list.append(',');
        try list.appendSlice(part);
        first = false;
    }
    try list.append('}');

    return list.toOwnedSlice();
}

fn mentorList(conn: *db.Db, allocator: std.mem.Allocator, writer: anytype) !void {
    var result = try conn.query(allocator, sql.list_mentors, &.{});
    defer result.deinit();

    try writer.print("id | name | email | timezone | status\n", .{});
    for (0..result.rowCount()) |row| {
        try writer.print(
            "{s} | {s} | {s} | {s} | {s}\n",
            .{
                result.value(row, 0),
                result.value(row, 1),
                result.value(row, 2),
                result.value(row, 3),
                result.value(row, 4),
            },
        );
    }
}

fn mentorAdd(conn: *db.Db, allocator: std.mem.Allocator, args: [][]const u8, writer: anytype) !void {
    const name = try requireFlag(args, "--name");
    const email = try requireFlag(args, "--email");
    const timezone = try requireFlag(args, "--timezone");
    const focus_raw = getFlag(args, "--focus-areas") orelse "";
    const focus = try toPgTextArray(allocator, focus_raw);
    defer allocator.free(focus);

    var result = try conn.query(allocator, sql.insert_mentor, &.{ name, email, timezone, focus });
    defer result.deinit();

    try writer.print("mentor_id={s}\n", .{result.value(0, 0)});
}

fn availabilityAdd(conn: *db.Db, allocator: std.mem.Allocator, args: [][]const u8, writer: anytype) !void {
    const mentor_id = try requireFlag(args, "--mentor-id");
    _ = try std.fmt.parseInt(u64, mentor_id, 10);

    const start_raw = try requireFlag(args, "--start");
    const end_raw = try requireFlag(args, "--end");
    const max_sessions = try requireFlag(args, "--max-sessions");
    _ = try std.fmt.parseInt(u32, max_sessions, 10);

    const notes = getFlag(args, "--notes") orelse "";

    const start = try normalizeTimestamp(allocator, start_raw);
    defer allocator.free(start);
    const end = try normalizeTimestamp(allocator, end_raw);
    defer allocator.free(end);
    try ensureChronological(start, end);

    var result = try conn.query(allocator, sql.insert_availability, &.{ mentor_id, start, end, max_sessions, notes });
    defer result.deinit();

    try writer.print("availability_id={s}\n", .{result.value(0, 0)});
}

fn availabilityList(conn: *db.Db, allocator: std.mem.Allocator, args: [][]const u8, writer: anytype) !void {
    const mentor_id = try requireFlag(args, "--mentor-id");
    _ = try std.fmt.parseInt(u64, mentor_id, 10);

    var result = try conn.query(allocator, sql.list_availability, &.{ mentor_id });
    defer result.deinit();

    try writer.print("id | mentor_id | start_ts | end_ts | max_sessions | notes\n", .{});
    for (0..result.rowCount()) |row| {
        try writer.print(
            "{s} | {s} | {s} | {s} | {s} | {s}\n",
            .{
                result.value(row, 0),
                result.value(row, 1),
                result.value(row, 2),
                result.value(row, 3),
                result.value(row, 4),
                result.value(row, 5),
            },
        );
    }
}

fn bookingAdd(conn: *db.Db, allocator: std.mem.Allocator, args: [][]const u8, writer: anytype) !void {
    const mentor_id = try requireFlag(args, "--mentor-id");
    _ = try std.fmt.parseInt(u64, mentor_id, 10);

    const scholar = try requireFlag(args, "--scholar");
    const start_raw = try requireFlag(args, "--start");
    const end_raw = try requireFlag(args, "--end");
    const status = getFlag(args, "--status") orelse "scheduled";

    const start = try normalizeTimestamp(allocator, start_raw);
    defer allocator.free(start);
    const end = try normalizeTimestamp(allocator, end_raw);
    defer allocator.free(end);
    try ensureChronological(start, end);

    var result = try conn.query(allocator, sql.insert_booking, &.{ mentor_id, scholar, start, end, status });
    defer result.deinit();

    try writer.print("booking_id={s}\n", .{result.value(0, 0)});
}

fn bookingList(conn: *db.Db, allocator: std.mem.Allocator, args: [][]const u8, writer: anytype) !void {
    const mentor_id = try requireFlag(args, "--mentor-id");
    _ = try std.fmt.parseInt(u64, mentor_id, 10);

    const status = getFlag(args, "--status") orelse "";
    const start_raw = getFlag(args, "--start");
    const end_raw = getFlag(args, "--end");

    var start_value: []const u8 = "";
    var end_value: []const u8 = "";

    if (start_raw) |start_input| {
        start_value = try normalizeTimestamp(allocator, start_input);
        defer allocator.free(start_value);
    }
    if (end_raw) |end_input| {
        end_value = try normalizeTimestamp(allocator, end_input);
        defer allocator.free(end_value);
    }
    if (start_value.len > 0 and end_value.len > 0) {
        try ensureChronological(start_value, end_value);
    }

    var result = try conn.query(allocator, sql.list_bookings, &.{ mentor_id, status, start_value, end_value });
    defer result.deinit();

    try writer.print("id | mentor_id | mentor_name | scholar | start_ts | end_ts | status\n", .{});
    for (0..result.rowCount()) |row| {
        try writer.print(
            "{s} | {s} | {s} | {s} | {s} | {s} | {s}\n",
            .{
                result.value(row, 0),
                result.value(row, 1),
                result.value(row, 2),
                result.value(row, 3),
                result.value(row, 4),
                result.value(row, 5),
                result.value(row, 6),
            },
        );
    }
}

fn capacityRange(conn: *db.Db, allocator: std.mem.Allocator, args: [][]const u8, writer: anytype) !void {
    const start_raw = try requireFlag(args, "--start");
    const end_raw = try requireFlag(args, "--end");

    const start = try normalizeTimestamp(allocator, start_raw);
    defer allocator.free(start);
    const end = try normalizeTimestamp(allocator, end_raw);
    defer allocator.free(end);
    try ensureChronological(start, end);

    var result = try conn.query(allocator, sql.capacity_range, &.{ start, end });
    defer result.deinit();

    try writer.print("id | name | available_sessions | booked_sessions | remaining_sessions\n", .{});
    for (0..result.rowCount()) |row| {
        try writer.print(
            "{s} | {s} | {s} | {s} | {s}\n",
            .{
                result.value(row, 0),
                result.value(row, 1),
                result.value(row, 2),
                result.value(row, 3),
                result.value(row, 4),
            },
        );
    }
}

fn utilizationRange(conn: *db.Db, allocator: std.mem.Allocator, args: [][]const u8, writer: anytype) !void {
    const start_raw = try requireFlag(args, "--start");
    const end_raw = try requireFlag(args, "--end");

    const start = try normalizeTimestamp(allocator, start_raw);
    defer allocator.free(start);
    const end = try normalizeTimestamp(allocator, end_raw);
    defer allocator.free(end);
    try ensureChronological(start, end);

    var result = try conn.query(allocator, sql.utilization_range, &.{ start, end });
    defer result.deinit();

    try writer.print("id | name | available_sessions | booked_sessions | utilization_pct\n", .{});
    for (0..result.rowCount()) |row| {
        try writer.print(
            "{s} | {s} | {s} | {s} | {s}\n",
            .{
                result.value(row, 0),
                result.value(row, 1),
                result.value(row, 2),
                result.value(row, 3),
                result.value(row, 4),
            },
        );
    }
}

fn printUsage(writer: anytype) !void {
    try writer.print(
        "groupscholar-mentor-availability-ledger\n\n" ++
            "Commands:\n" ++
            "  mentor list\n" ++
            "  mentor add --name NAME --email EMAIL --timezone TZ [--focus-areas a,b]\n" ++
            "  availability add --mentor-id ID --start TS --end TS --max-sessions N [--notes TEXT]\n" ++
            "  availability list --mentor-id ID\n" ++
            "  booking add --mentor-id ID --scholar NAME --start TS --end TS [--status STATUS]\n" ++
            "  booking list --mentor-id ID [--status STATUS] [--start TS] [--end TS]\n" ++
            "  capacity range --start TS --end TS\n" ++
            "  utilization range --start TS --end TS\n",
        .{},
    );
}

fn printMentorUsage(writer: anytype) !void {
    try writer.print(
        "mentor commands:\n" ++
            "  mentor list\n" ++
            "  mentor add --name NAME --email EMAIL --timezone TZ [--focus-areas a,b]\n",
        .{},
    );
}

fn printAvailabilityUsage(writer: anytype) !void {
    try writer.print(
        "availability commands:\n" ++
            "  availability add --mentor-id ID --start TS --end TS --max-sessions N [--notes TEXT]\n" ++
            "  availability list --mentor-id ID\n",
        .{},
    );
}

fn printBookingUsage(writer: anytype) !void {
    try writer.print(
        "booking commands:\n" ++
            "  booking add --mentor-id ID --scholar NAME --start TS --end TS [--status STATUS]\n" ++
            "  booking list --mentor-id ID [--status STATUS] [--start TS] [--end TS]\n",
        .{},
    );
}

fn printCapacityUsage(writer: anytype) !void {
    try writer.print(
        "capacity commands:\n" ++
            "  capacity range --start TS --end TS\n",
        .{},
    );
}

fn printUtilizationUsage(writer: anytype) !void {
    try writer.print(
        "utilization commands:\n" ++
            "  utilization range --start TS --end TS\n",
        .{},
    );
}
