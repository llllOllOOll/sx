const sx = @import("sx");

pub fn main() !void {
    const name = "Alice";
    const age: u32 = 30;

    var f = try sx.fs.open("out.txt", .write);
    defer f.close();
    try f.print("name: {s}\n", .{name});
    try f.print("age: {d}\n", .{age});
    try f.writeln("done!");

    // verify by reading back
    const data = try sx.fs.read("out.txt");
    sx.println("{s}", .{data});
}
