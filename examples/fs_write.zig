const sx = @import("sx");

pub fn main() !void {
    try sx.fs.write("output.txt", "Hello from sx.fs.write!\n");
    sx.println("File written successfully.", .{});
}
