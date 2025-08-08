const std = @import("std");
const c = @cImport({
    @cInclude("libpq-fe.h");
});

pub const Db = struct {
    conn: *c.PGconn,

    pub fn connect(allocator: std.mem.Allocator) !Db {
        const url = std.process.getEnvVarOwned(allocator, "DATABASE_URL") catch return error.MissingDatabaseUrl;
        defer allocator.free(url);

        const conn = c.PQconnectdb(url.ptr) orelse return error.ConnectionFailed;
        if (c.PQstatus(conn) != c.CONNECTION_OK) {
            c.PQfinish(conn);
            return error.ConnectionFailed;
        }

        return Db{ .conn = conn };
    }

    pub fn deinit(self: *Db) void {
        c.PQfinish(self.conn);
    }

    pub fn exec(self: *Db, query: []const u8) !void {
        const res = c.PQexec(self.conn, query.ptr) orelse return error.QueryFailed;
        defer c.PQclear(res);

        const status = c.PQresultStatus(res);
        if (status != c.PGRES_COMMAND_OK and status != c.PGRES_TUPLES_OK) {
            return error.QueryFailed;
        }
    }

    pub fn query(self: *Db, allocator: std.mem.Allocator, query_text: []const u8, params: []const []const u8) !QueryResult {
        var buffers = std.ArrayList([]u8).init(allocator);
        defer {
            for (buffers.items) |item| allocator.free(item);
            buffers.deinit();
        }

        var param_values = try allocator.alloc([*:0]const u8, params.len);
        defer allocator.free(param_values);

        for (params, 0..) |param, idx| {
            var buf = try allocator.alloc(u8, param.len + 1);
            std.mem.copyForwards(u8, buf[0..param.len], param);
            buf[param.len] = 0;
            try buffers.append(buf);
            param_values[idx] = buf.ptr;
        }

        const res = c.PQexecParams(
            self.conn,
            query_text.ptr,
            @intCast(params.len),
            null,
            @ptrCast(param_values.ptr),
            null,
            null,
            0,
        ) orelse return error.QueryFailed;

        const status = c.PQresultStatus(res);
        if (status != c.PGRES_COMMAND_OK and status != c.PGRES_TUPLES_OK) {
            c.PQclear(res);
            return error.QueryFailed;
        }

        return QueryResult{ .res = res };
    }
};

pub const QueryResult = struct {
    res: *c.PGresult,

    pub fn deinit(self: *QueryResult) void {
        c.PQclear(self.res);
    }

    pub fn rowCount(self: *QueryResult) usize {
        return @intCast(c.PQntuples(self.res));
    }

    pub fn colCount(self: *QueryResult) usize {
        return @intCast(c.PQnfields(self.res));
    }

    pub fn value(self: *QueryResult, row: usize, col: usize) []const u8 {
        const ptr = c.PQgetvalue(self.res, @intCast(row), @intCast(col));
        return std.mem.span(ptr);
    }
};
