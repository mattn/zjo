const std = @import("std");

pub fn main() anyerror!void {
    var allocator = std.heap.page_allocator;
    var p = std.json.Parser.init(allocator, false);
    defer p.deinit();

    const args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);

    const stdout = std.io.getStdOut().writer();

    var is_array = false;

    var files = std.ArrayList([]const u8).init(allocator);
    defer files.deinit();

    for (args[1..args.len]) |aa| {
        if (std.mem.eql(u8, aa, "-a")) {
            is_array = true;
        } else {
            try files.append(aa);
        }
    }

    if (is_array) {
        var a = std.json.Array.init(allocator);
        defer a.deinit();

        for (files.items) |aa| {
            if (p.parse(aa)) |v| {
                try a.append(v.root);
            } else |_| {
                try a.append(std.json.Value{ .String = aa });
            }
        }
        try (std.json.Value{ .Array = a }).jsonStringify(.{}, stdout);
    } else {
        var m = std.json.ObjectMap.init(allocator);
        defer m.deinit();

        for (files.items) |aa| {
            var it = std.mem.split(u8, aa, "=");
            var key = it.next() orelse "";
            var value = it.next() orelse "";
            if (p.parse(value)) |v| {
                try m.put(key, v.root);
            } else |_| {
                try m.put(key, std.json.Value{ .String = value });
            }
        }
        try (std.json.Value{ .Object = m }).jsonStringify(.{}, stdout);
    }
    _ = try stdout.write("\n");
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
