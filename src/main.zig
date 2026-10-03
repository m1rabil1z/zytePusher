const std = @import("std");
const Platform = @import("platform.zig");
const BP = @import("BytePusher.zig");

pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
}
