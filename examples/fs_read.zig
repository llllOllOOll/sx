const sx = @import("sx");

pub fn main() !void {
    const data = try sx.fs.read("examples/fs_read.zig");
    sx.println("{s}", .{data});
}
