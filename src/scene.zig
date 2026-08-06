const SpriteBatch = @import("draw_spr.zig").SpriteBatch;

const math = @import("math.zig");
const anim = @import("anim.zig");

pub const Scene = struct {
    animation: anim.FramesAnimation,

    const Self = @This();
    pub fn init() Self {
        const source_rect: math.Box = .init(0, 0, 32, 32);
        const dest_rect: math.Box = .init(0, 0, 64, 64);
        const frames = &[_]u8{ 0, 1, 2, 3, 4 };
        return .{ .animation = .init(7.2, frames, source_rect, dest_rect) };
    }
};

pub fn renderScene(batch: SpriteBatch, scene: Scene, alpha: f32) void {
    _ = alpha;
    batch.draw_bg(0, 0, 64, 64, 5, 5, 10, 10);
    anim.renderFramesAnimation(batch, &scene.animation);
}

pub fn updateScene(scene: *Scene, dt: f64) void {
    anim.updateFramesAnimation(&scene.animation, dt);
}
