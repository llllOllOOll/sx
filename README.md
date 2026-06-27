# sx

High-level helpers for Zig CLI programs: stdin, stdout, filesystem, args and random — without the ceremony.

## Quick install

In your project, add `sx` as a dependency:

```bash
zig fetch --save git+https://github.com/llllOllOOll/sx
```

This adds the following to your `build.zig.zon`:

```zig
.{
    .dependencies = .{
        .sx = .{
            .url = "git+https://github.com/llllOllOOll/sx",
            .hash = "...",
        },
    },
}
```

Then in your `build.zig`:

```zig
const sx_module = b.dependency("sx", .{
    .target = target,
    .optimize = optimize,
}).module("sx");
```

## Why sx exists

I love Zig. I use it in every project I work on, and I deeply respect its philosophy — explicit memory management, no hidden allocations, IO as an interface. These are the right decisions for systems programming.

But Zig's philosophy optimizes for the hardest cases. When I'm writing a quick CLI tool, a small script, or exploring an idea without an LSP or AI code completion, the ceremony starts to feel heavy:

**Opening a file in Zig:**
```zig
const file = try std.Io.Dir.cwd().openFile(init.io, "foo.txt", .{});
defer file.close(init.io);
var buf: [4096]u8 = undefined;
var reader = file.reader(init.io, &buf);
```

**Opening a file with sx:**
```zig
const data = try sx.fs.read("foo.txt");
```

`sx` does not try to replace the Zig standard library. It sits on top of it. When you need full control, use `std` directly. `sx` is for the cases where you just want to get things done.

## API

### Print
```zig
sx.println("Hello, {s}!", .{"world"});
```

### stdin
```zig
const n = try sx.stdin.readInt(u8);         // read a single integer
const line = try sx.stdin.readLine();        // read a line — null on EOF

// scan — reads values separated by any whitespace (space or newline)
var a: f32 = undefined;
var b: f32 = undefined;
try sx.stdin.scan(.{ &a, &b });

// scanln — reads values from the same line only, stops at newline
try sx.stdin.scanln(.{ &a, &b });

// scanf — explicit format, like C/Go
var name: []u8 = undefined;
var age: u32 = undefined;
try sx.stdin.scanf("%s %d", .{ &name, &age });
```

### Random
```zig
const n = sx.rand.int(u8, 1, 100);        // random integer in range [1, 100]
```

### Args
```zig
sx.args.init(init.minimal.args);           // call once in main

const all   = try sx.args.all();           // all args including binary name
const rest  = try sx.args.rest();          // args without binary name
const first = try sx.args.get(1);          // arg at index — null if not present
```

### Filesystem
```zig
const data = try sx.fs.read("foo.txt");         // read entire file
try sx.fs.write("foo.txt", data);               // write to file

var iter = try sx.fs.lines("foo.txt");          // line iterator
while (try iter.next()) |line| { ... }          // null on EOF
```

## Examples

### Hello, World
```zig
const sx = @import("sx");

pub fn main() !void {
    sx.println("hello, world", .{});
}
```

### Guess the number
```zig
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
```

### Read a file line by line
```zig
const sx = @import("sx");

pub fn main() !void {
    var iter = try sx.fs.lines("foo.txt");
    while (try iter.next()) |line| {
        sx.println("{s}", .{line});
    }
}
```

### Calculator
```zig
const std = @import("std");
const sx = @import("sx");

pub fn main(init: std.process.Init) !void {
    sx.args.init(init.minimal.args);
    const args = try sx.args.all();
    const a = try std.fmt.parseFloat(f32, args[1]);
    const b = try std.fmt.parseFloat(f32, args[3]);
    const result: f32 = if (std.mem.eql(u8, args[2], "+"))
        a + b
    else if (std.mem.eql(u8, args[2], "-"))
        a - b
    else if (std.mem.eql(u8, args[2], "*"))
        a * b
    else
        a / b;
    sx.println("Result: {d:.2}", .{result});
}
```

### Scan input
```zig
const sx = @import("sx");

pub fn main() !void {
    sx.println("Enter name and age:", .{});
    var name: []u8 = undefined;
    var age: u32 = undefined;
    try sx.stdin.scanf("%s %d", .{ &name, &age });
    sx.println("Hello {s}, you are {d} years old!", .{ name, age });
}
```

## Running the examples

```bash
# hello world
zig run examples/hello.zig --dep sx -Mroot=examples/hello.zig -Msx=src/sx.zig

# temperatures
zig run examples/temperatures.zig --dep sx -Mroot=examples/temperatures.zig -Msx=src/sx.zig

# guess the number
zig run examples/guess_number.zig --dep sx -Mroot=examples/guess_number.zig -Msx=src/sx.zig

# calculator
zig run examples/calculator.zig --dep sx -Mroot=examples/calculator.zig -Msx=src/sx.zig -- 2 + 2

# char counter
echo "hello world" | zig run examples/char_counter.zig --dep sx -Mroot=examples/char_counter.zig -Msx=src/sx.zig

# args
zig run examples/args.zig --dep sx -Mroot=examples/args.zig -Msx=src/sx.zig -- hello world

# read file
zig run examples/fs_read.zig --dep sx -Mroot=examples/fs_read.zig -Msx=src/sx.zig

# write file
zig run examples/fs_write.zig --dep sx -Mroot=examples/fs_write.zig -Msx=src/sx.zig

# lines iterator
zig run examples/fs_lines.zig --dep sx -Mroot=examples/fs_lines.zig -Msx=src/sx.zig
```

## Why not just use std?

Compare reading a file across languages:

**Go:**
```go
data, err := os.ReadFile("foo.txt")
```

**Rust:**
```rust
let data = fs::read_to_string("foo.txt")?;
```

**Zig (std):**
```zig
const file = try std.Io.Dir.cwd().openFile(init.io, "foo.txt", .{});
defer file.close(init.io);
var buf: [4096]u8 = undefined;
var reader = file.reader(init.io, &buf);
```

**Zig (sx):**
```zig
const data = try sx.fs.read("foo.txt");
```

Go and Rust hide the buffer internally — and that's fine for most use cases. `sx` does the same for Zig, without fighting the language.

The verbosity of `std` is intentional — it gives you full control over memory, IO backends, and buffer lifetimes. `sx` is not a criticism of that design. It is an optional convenience layer for the cases where that level of control is not needed.

## Philosophy

`sx` is not a framework, not a replacement for `std`, and not a statement against Zig's design decisions. It is a personal utility library for cases where simplicity matters more than control.

> When you need full control, use `std`. When you just want to get things done, use `sx`.

## Compatibility

`sx` targets `0.17.0-dev.956+2dca73595` and above. The Zig API is still evolving before 1.0 — pin your Zig version if you depend on `sx` in a real project.

## Contributing

`sx` is a personal library, but feedback and ideas are welcome. If you think a common pattern deserves a simpler API, open an issue with a comparison — show the `std` version, show what `sx` could look like, and make the case.

If you use Zig and want to chat, join the Spider web framework community on Discord: https://discord.gg/PCPyzg8HY

Or reach out directly: 7b37b3@gmail.com
