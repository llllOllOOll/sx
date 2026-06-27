const std = @import("std");

var gpa = std.heap.page_allocator;
var threaded: std.Io.Threaded = undefined;
var arena_allocator: std.heap.ArenaAllocator = undefined;
var io: std.Io = undefined;
var initialized: bool = false;

var stdin_reader: std.Io.File.Reader = undefined;
var stdin_reader_buf: [1024]u8 = undefined;
var stdin_reader_init: bool = false;

fn ensureInit() void {
    if (initialized) return;
    threaded = std.Io.Threaded.init(gpa, .{});
    arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    io = threaded.io();
    initialized = true;
}

fn getStdinReader() *std.Io.File.Reader {
    if (!stdin_reader_init) {
        stdin_reader = std.Io.File.Reader.initStreaming(std.Io.File.stdin(), io, &stdin_reader_buf);
        stdin_reader_init = true;
    }
    return &stdin_reader;
}

pub const rand = struct {
    pub fn int(comptime T: type, min: T, max: T) T {
        ensureInit();
        var buf: [@sizeOf(T)]u8 = undefined;
        io.vtable.random(io.userdata, &buf);
        const raw = std.mem.bytesToValue(T, &buf);
        const range = @as(u64, @intCast(max -% min +% 1));
        return min + @as(T, @intCast(@as(u64, @intCast(raw)) % range));
    }
};

pub const stdin = struct {
    pub fn readInt(comptime T: type) !T {
        ensureInit();
        const line = try readLine() orelse return error.EndOfStream;
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        return try std.fmt.parseInt(T, trimmed, 10);
    }

    pub fn readLine() !?[]u8 {
        ensureInit();
        const arena = arena_allocator.allocator();
        var line_buf: [1024]u8 = undefined;
        var i: usize = 0;
        while (i < line_buf.len) {
            var byte_buf: [1]u8 = undefined;
            var slices = [_][]u8{&byte_buf};
            _ = getStdinReader().interface.readVec(&slices) catch |err| switch (err) {
                error.EndOfStream => {
                    if (i == 0) return null;
                    break;
                },
                else => |e| return e,
            };
            if (byte_buf[0] == '\n') break;
            if (byte_buf[0] == '\r') continue;
            line_buf[i] = byte_buf[0];
            i += 1;
        }
        if (i == 0) return null;
        const result = try arena.alloc(u8, i);
        @memcpy(result, line_buf[0..i]);
        return result;
    }

    pub fn scan(tuple: anytype) !void {
        const info = @typeInfo(@TypeOf(tuple));
        const s = info.@"struct";
        inline for (s.field_names, s.field_types) |name, field_type| {
            const ptr: field_type = @field(tuple, name);
            const T = @typeInfo(field_type).pointer.child;
            const token = try readToken();
            ptr.* = try parseToken(T, token);
        }
    }

    pub fn scanln(tuple: anytype) !void {
        const info = @typeInfo(@TypeOf(tuple));
        const s = info.@"struct";
        inline for (s.field_names, s.field_types) |name, field_type| {
            const ptr: field_type = @field(tuple, name);
            const T = @typeInfo(field_type).pointer.child;
            const token = try readTokenLine();
            ptr.* = try parseToken(T, token);
        }
    }

    fn readToken() ![]u8 {
        const reader = getStdinReader();
        var buf: [1024]u8 = undefined;
        var i: usize = 0;
        while (true) {
            var byte_buf: [1]u8 = undefined;
            var slices = [_][]u8{&byte_buf};
            const n = reader.interface.readVec(&slices) catch |err| switch (err) {
                error.EndOfStream => {
                    if (i == 0) return error.EndOfStream;
                    break;
                },
                else => |e| return e,
            };
            if (n == 0) {
                if (i == 0) return error.EndOfStream;
                break;
            }
            const byte = byte_buf[0];
            if (std.ascii.isWhitespace(byte)) {
                if (i > 0) break;
            } else {
                if (i >= buf.len) return error.Overflow;
                buf[i] = byte;
                i += 1;
            }
        }
        const arena = arena_allocator.allocator();
        const result = try arena.alloc(u8, i);
        @memcpy(result, buf[0..i]);
        return result;
    }

    fn readTokenLine() ![]u8 {
        const reader = getStdinReader();
        var buf: [1024]u8 = undefined;
        var i: usize = 0;
        while (true) {
            const byte = reader.interface.peekByte() catch |err| switch (err) {
                error.EndOfStream => {
                    if (i == 0) return error.EndOfStream;
                    break;
                },
                else => |e| return e,
            };
            if (byte == '\n') {
                if (i == 0) return error.EndOfLine;
                break;
            }
            if (byte == '\r') {
                reader.interface.toss(1);
                continue;
            }
            if (byte == ' ' or byte == '\t') {
                if (i > 0) break;
                reader.interface.toss(1);
            } else {
                if (i >= buf.len) return error.Overflow;
                reader.interface.toss(1);
                buf[i] = byte;
                i += 1;
            }
        }
        if (i == 0) return error.EndOfLine;
        const arena = arena_allocator.allocator();
        const result = try arena.alloc(u8, i);
        @memcpy(result, buf[0..i]);
        return result;
    }

    fn parseToken(comptime T: type, token: []u8) !T {
        switch (@typeInfo(T)) {
            .int => return std.fmt.parseInt(T, token, 10),
            .float => return std.fmt.parseFloat(T, token),
            .pointer => |ptr_info| {
                if (ptr_info.size == .slice and ptr_info.child == u8) {
                    return token;
                }
                @compileError("unsupported pointer type: " ++ @typeName(T));
            },
            else => @compileError("unsupported type: " ++ @typeName(T)),
        }
    }
};

pub const LinesIterator = struct {
    file: std.Io.File,
    reader: std.Io.File.Reader,
    line_buf: [1024]u8 = undefined,
    done: bool = false,

    pub fn next(self: *LinesIterator) !?[]u8 {
        if (self.done) return null;
        var i: usize = 0;
        var hit_newline: bool = false;
        while (i < self.line_buf.len) {
            var byte_buf: [1]u8 = undefined;
            var slices = [_][]u8{&byte_buf};
            const nread = self.reader.interface.readVec(&slices) catch |err| switch (err) {
                error.EndOfStream => {
                    if (i == 0 and !hit_newline) {
                        self.file.close(io);
                        self.done = true;
                        return null;
                    }
                    break;
                },
                else => |e| return e,
            };
            if (nread == 0) {
                if (i == 0 and !hit_newline) {
                    self.file.close(io);
                    self.done = true;
                    return null;
                }
                break;
            }
            if (byte_buf[0] == '\n') {
                hit_newline = true;
                break;
            }
            if (byte_buf[0] == '\r') continue;
            self.line_buf[i] = byte_buf[0];
            i += 1;
        }
        if (i == 0 and !hit_newline) {
            self.file.close(io);
            self.done = true;
            return null;
        }
        return self.line_buf[0..i];
    }
};

pub const fs = struct {
    pub fn read(path: []const u8) ![]u8 {
        ensureInit();
        return std.Io.Dir.cwd().readFileAlloc(io, path, arena_allocator.allocator(), .unlimited);
    }

    pub fn write(path: []const u8, data: []const u8) !void {
        ensureInit();
        try std.Io.Dir.cwd().writeFile(io, .{
            .sub_path = path,
            .data = data,
        });
    }

    pub fn lines(path: []const u8) !LinesIterator {
        ensureInit();
        const file = try std.Io.Dir.cwd().openFile(io, path, .{});
        const reader_buf = try arena_allocator.allocator().alloc(u8, 4096);
        return .{
            .file = file,
            .reader = std.Io.File.Reader.initStreaming(file, io, reader_buf),
        };
    }
};

pub const args = struct {
    var cached: [][]u8 = undefined;
    var cached_init: bool = false;

    pub fn init(a: std.process.Args) void {
        ensureInit();
        const vector = a.vector;
        const len = vector.len;
        const arena = arena_allocator.allocator();
        cached = arena.alloc([]u8, len) catch @panic("OOM");
        for (vector, 0..) |arg_ptr, i| {
            const s = std.mem.sliceTo(arg_ptr, 0);
            cached[i] = arena.dupe(u8, s) catch @panic("OOM");
        }
        cached_init = true;
    }

    pub fn all() ![][]u8 {
        if (!cached_init) return error.NotInitialized;
        return cached;
    }

    pub fn rest() ![][]u8 {
        if (!cached_init) return error.NotInitialized;
        if (cached.len == 0) return &[_][]u8{};
        return cached[1..];
    }

    pub fn get(index: usize) !?[]u8 {
        if (!cached_init) return error.NotInitialized;
        if (index >= cached.len) return null;
        return cached[index];
    }
};

pub fn println(comptime fmt: []const u8, fmt_args: anytype) void {
    ensureInit();
    var buf: [2048]u8 = undefined;
    var fw = std.Io.File.Writer.initStreaming(std.Io.File.stdout(), io, &buf);
    fw.interface.print(fmt, fmt_args) catch {};
    _ = fw.interface.write("\n") catch {};
    fw.interface.flush() catch {};
}
