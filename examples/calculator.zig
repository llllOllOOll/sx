const std = @import("std");
const sx = @import("sx");

pub fn main(init: std.process.Init) !void {
    sx.args.init(init.minimal.args);
    const args = try sx.args.all();
    const a: f32 = try std.fmt.parseFloat(f32, args[1]);
    const b: f32 = try std.fmt.parseFloat(f32, args[3]);
    const result: f32 = if (std.mem.eql(u8, args[2], "+"))
        a + b
    else if (std.mem.eql(u8, args[2], "-"))
        a - b
    else if (std.mem.eql(u8, args[2], "*"))
        a * b
    else if (std.mem.eql(u8, args[2], "/"))
        a / b
    else {
        sx.println("Operação inválida: {s}", .{args[2]});
        return;
    };
    sx.println("Result: {d:.2}", .{result});
}
