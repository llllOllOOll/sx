const std = @import("std");
const sx = @import("sx");

pub fn main(init: std.process.Init) !void {
    sx.args.init(init.minimal.args);
    var nc: u64 = 0;
    while (try sx.stdin.readLine()) |line| {
        nc += line.len + 1;
    }
    sx.println("{d}", .{nc});
}
