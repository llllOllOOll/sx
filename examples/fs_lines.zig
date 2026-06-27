const sx = @import("sx");

pub fn main() !void {
    var iter = try sx.fs.lines("examples/fs_lines.zig");
    var n: u32 = 1;
    while (try iter.next()) |line| {
        sx.println("{d:3}: {s}", .{ n, line });
        n += 1;
    }
}
