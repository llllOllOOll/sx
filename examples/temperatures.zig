const sx = @import("sx");

pub fn main() !void {
    var fahr: f32 = 0;
    while (fahr <= 300) : (fahr += 20)
        sx.println("{d:3.0}\t{d:6.1}", .{ fahr, (5.0 / 9.0) * (fahr - 32) });
}
