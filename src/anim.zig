const math = @import("math.zig");
const Box = math.Box;
const SpriteBatch = @import("draw_spr.zig").SpriteBatch;

pub const FramesAnimation = struct {
    fps: f32,

    t: f32,
    frame: u8,
    source: Box,
    dest: Box,

    frames: []u8,

    const Self = @This();
    pub fn update(self: *Self, dt: f32) void {
        self.t += dt;

        const frame_durationMs = 1000.0 / self.fps;
        const elapsed_frames = self.t / frame_durationMs;

        if (elapsed_frames > 1) {
            const leftover_frames = @mod(elapsed_frames, frame_durationMs);
            self.t = leftover_frames;
            self.frame += 1;
            if (self.frame == self.frames.len) {
                self.frame = 0;
            }
        }
    }

    pub fn render(self: Self, batch: SpriteBatch) void {
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
};
