const std = @import("std");
const sx = @import("sx");

pub fn main(init: std.process.Init) !void {
    sx.args.init(init.minimal.args);

    // scan — any whitespace separator (space or newline)
    sx.println("--- scan ---", .{});
    sx.println("Enter two numbers (can be on different lines):", .{});
    var a: f32 = undefined;
    var b: f32 = undefined;
    try sx.stdin.scan(.{ &a, &b });
    sx.println("a={d:.1} b={d:.1} sum={d:.1}", .{ a, b, a + b });

    // scanln — stops at newline
    sx.println("--- scanln ---", .{});
    sx.println("Enter two numbers on the same line:", .{});
    var c: f32 = undefined;
    var d: f32 = undefined;
    try sx.stdin.scanln(.{ &c, &d });
    sx.println("c={d:.1} d={d:.1} sum={d:.1}", .{ c, d, c + d });

    // scanf — explicit format
    sx.println("--- scanf ---", .{});
    sx.println("Enter name and age:", .{});
    var name: []u8 = undefined;
    var age: u32 = undefined;
    try sx.stdin.scanf("%s %d", .{ &name, &age });
    sx.println("name={s} age={d}", .{ name, age });
}
