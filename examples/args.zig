const std = @import("std");
const sx = @import("sx");

pub fn main(init: std.process.Init) !void {
    sx.args.init(init.minimal.args);

    const all = try sx.args.all();
    sx.println("binary: {s}", .{all[0]});

    const rest = try sx.args.rest();
    for (rest) |arg| {
        sx.println("arg: {s}", .{arg});
    }

    const first = try sx.args.get(1);
    if (first) |f| {
        sx.println("first: {s}", .{f});
    }
}
