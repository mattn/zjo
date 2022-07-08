const std = @import("std");

pub fn main() anyerror!void {
    var allocator = std.heap.page_allocator;
    var p = std.json.Parser.init(allocator, false);
    defer p.deinit();

    var args = try std.process.argsWithAllocator(allocator);

    const stdout = std.io.getStdOut().writer();

    _ = args.next();

    var m = std.json.ObjectMap.init(allocator);
    defer m.deinit();

    var a = std.json.Array.init(allocator);
    defer a.deinit();

    var is_array = false;
    while (args.next()) |aa| {
        if (std.mem.eql(u8, aa, "-a")) {
            is_array = true;
            continue;
        }

        if (is_array) {
            if (p.parse(aa)) |v| {
                try a.append(v.root);
            } else |_| {
                try a.append(std.json.Value{ .String = aa });
            }
        } else {
            var it = std.mem.split(u8, aa, "=");
            var key = it.next() orelse "";
            var value = it.next() orelse "";
            if (p.parse(value)) |v| {
                try m.put(key, v.root);
            } else |_| {
                try m.put(key, std.json.Value{ .String = value });
            }
        }
    }
    if (is_array) {
        try (std.json.Value{ .Array = a }).jsonStringify(.{}, stdout);
    } else {
        try (std.json.Value{ .Object = m }).jsonStringify(.{}, stdout);
    }
    _ = try stdout.write("\n");
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
