const BytePusher = @This();

const std = @import("std");

const KEY_COUNT: u32 = 16;
const MEMORY_SIZE: u32 = 16777216;
const PC_ADDRESS = 0x2;
pub const VIDEO_HEIGHT = 256;
pub const VIDEO_WIDTH = 256;

keypad: [KEY_COUNT]u8,
memory: [MEMORY_SIZE]u8,
video: [VIDEO_HEIGHT * VIDEO_WIDTH]u32,
pc: u32,

pub fn init(self: *BytePusher) void {
    @memset(&self.keypad, 0);
    @memset(&self.memory, 0);
    @memset(&self.video, 0);
    self.pc = PC_ADDRESS;
}

pub fn loadROM(self: *BytePusher, io: std.Io, filename: [:0]const u8) !void {
    _ = try std.Io.Dir.cwd().readFile(io, filename, self.memory[0..]);
}

pub fn inloop(self: *BytePusher) void {
    self.pc = (@as(u32, self.memory[2]) << 16) | (@as(u32, self.memory[3]) << 8) | @as(u32, self.memory[4]);

    for (0..65536) |_| {
        const a = (@as(u32, self.memory[self.pc]) << 16) | (@as(u32, self.memory[self.pc + 1]) << 8) | (@as(u32, self.memory[self.pc + 2]));
        const b = (@as(u32, self.memory[self.pc + 3]) << 16) | (@as(u32, self.memory[self.pc + 4]) << 8) | (@as(u32, self.memory[self.pc + 5]));
        const c = (@as(u32, self.memory[self.pc + 6]) << 16) | (@as(u32, self.memory[self.pc + 7]) << 8) | (@as(u32, self.memory[self.pc + 8]));

        self.memory[b] = self.memory[a];
        self.pc = c;
    }
}

pub fn outloop(self: *BytePusher) void {
    var b0: u8 = 0;
    var b1: u8 = 0;

    for (0..8) |i| b1 |= self.keypad[i] << @intCast(i);
    for (8..16) |i| b0 |= self.keypad[i] << @intCast(i - 8);

    self.memory[0] = b0;
    self.memory[1] = b1;

    self.inloop();

    const disp_address = @as(u32, self.memory[5]) << 16;

    for (0..(VIDEO_HEIGHT * VIDEO_WIDTH)) |i| {
        const color = self.memory[disp_address + i];
        const r = ((color / 36) % 6) * 0x33;
        const g = ((color / 6) % 6) * 0x33;
        const b = (color % 6) * 0x33;

        if (color < 216) {
            self.video[i] = (@as(u32, r) << 24) | (@as(u32, g) << 16) | (@as(u32, b) << 8) | 0xFF;
        } else {
            self.video[i] = 0x000000FF;
        }
    }
}
