const std = @import("std");
const math = @import("math.zig");
const Box = math.Box;
const SpriteBatch = @import("draw_spr.zig").SpriteBatch;

pub const FramesAnimation = struct {
    fps: f32,

    t: f64 = 0,
    frame: u8 = 0,
    source: Box,
    dest: Box,

    frames: []const u8,

    pub fn init(fps: f32, frames: []const u8, source: Box, dest: Box) FramesAnimation {
        return .{ .fps = fps, .source = source, .dest = dest, .frames = frames };
    }
};

pub fn updateFramesAnimation(self: *FramesAnimation, dt: f64) void {
    self.t += dt;

    const frame_durationSeconds = 1 / self.fps;
    const elapsed_frames = self.t / frame_durationSeconds;

    if (elapsed_frames > 1) {
        const leftover_frames = @mod(elapsed_frames, frame_durationSeconds);
        self.t = leftover_frames * frame_durationSeconds;
        self.frame += 1;
        if (self.frame == self.frames.len) {
            self.frame = 0;
        }
    }
}

pub fn renderFramesAnimation(batch: SpriteBatch, self: *const FramesAnimation) void {
    const sw = self.source.w;
    const sh = self.source.h;
    const sx = self.source.x + self.frames[self.frame] * sw;
    const sy = self.source.y;
    const dx = self.dest.x;
    const dy = self.dest.y;
    const w = self.dest.w;
    const h = self.dest.h;

    batch.draw_spr(sx, sy, sw, sh, dx, dy, w / sw, h / sh);
}
