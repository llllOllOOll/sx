const sx = @import("sx");

pub fn main() !void {
    const n = sx.rand.int(u8, 1, 100);
    sx.println("Guess a number (1-100):", .{});
    while (true) {
        const guess = try sx.stdin.readInt(u8);
        if (guess == n) {
            sx.println("Correct!", .{});
            break;
        } else if (guess < n) {
            sx.println("Too low!", .{});
        } else {
            sx.println("Too high!", .{});
        }
    }
}
