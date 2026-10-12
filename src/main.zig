const std = @import("std");
const Platform = @import("platform.zig");
const BP = @import("BytePusher.zig");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    if (args.len != 3) {
        std.debug.print(
            "Usage : {s} <Scale> <ROM>\n",
            .{args[0]},
        );
        std.process.exit(1);
    }

    const videoScale = try std.fmt.parseInt(u32, args[1], 10);
    const cycleDelay: u32 = 1000 / 60;

    const romFilename = args[2];

    var platform: Platform = try .init(
        "z",
        videoScale * BP.VIDEO_WIDTH,
        videoScale * BP.VIDEO_HEIGHT,
        BP.VIDEO_WIDTH,
        BP.VIDEO_HEIGHT,
    );
    defer platform.deinit();

    var bytepusher: BP = .init();
    bytepusher.loadROM(init.io, romFilename) catch {
        std.log.err("Invalid ROM Argument", .{});
        return;
    };

    var lastCycleTime = std.Io.Clock.now(.real, init.io);

    while (Platform.processInput(&bytepusher.keypad)) {
        const currentTime = std.Io.Clock.now(.real, init.io);
        const dt: i32 = @intCast(lastCycleTime.durationTo(currentTime).toMilliseconds());

        if (dt > cycleDelay) {
            lastCycleTime = currentTime;

            bytepusher.outloop();

            const videoPitch = @sizeOf(u32) * BP.VIDEO_WIDTH;
            try platform.update(&bytepusher.video, videoPitch);
        }
    }
}
