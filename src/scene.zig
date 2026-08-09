const ds = @import("draw_spr.zig");
const SpriteBatch = ds.SpriteBatch;
const DebugBatch = ds.DebugBatch;
const FontBatch = ds.FontBatch;

const math = @import("math.zig");
const anim = @import("anim.zig");

const Camera = @import("camera.zig");

pub const Scene = struct {
    animation: anim.FramesAnimation,
    camera: Camera,

    t: f32 = 0,

    const Self = @This();
    pub fn init() Self {
        const source_rect: math.Box = .init(0, 0, 32, 32);
        const dest_rect: math.Box = .init(0, 0, 64, 64);
        const frames = &[_]u8{ 0, 1, 2, 3, 4 };
        return .{ .camera = .init(0, 0), .animation = .init(7.2, frames, source_rect, dest_rect) };
    }
};

pub fn renderScene(batch: SpriteBatch, scene: *Scene, alpha: f32) void {
    _ = alpha;
    _ = scene;

    batch.draw_bg(0, 0, 64, 64, 0, 0, 1, 1);
    //batch.draw_spr(0, 0, 32, 32, 0, 0, 2, 2);
    //scene.animation.dest.x = 0;
    //scene.animation.dest.y = 0;
    //anim.renderFramesAnimation(batch, &scene.animation);
    //{
    //    const i = 1;
    //    scene.animation.dest.x = @floatFromInt(i % 30 * 30);
    //    scene.animation.dest.y = @floatFromInt(i / 30 * 30);
    //    anim.renderFramesAnimation(batch, &scene.animation);
    //}

    //for (0..1000) |i| {
    //    scene.animation.dest.x = @floatFromInt(i % 30 * 30);
    //    scene.animation.dest.y = @floatFromInt(i / 30 * 30);
    //    //anim.renderFramesAnimation(batch, &scene.animation);
    //}
}

pub fn updateScene(scene: *Scene, dt: f64) void {
    scene.t += @floatCast(dt);
    anim.updateFramesAnimation(&scene.animation, dt);
    //scene.camera.position[0] = @sin(scene.t) * 200;
    //scene.camera.zoom = @sin(scene.t) * 0.5;
}

pub fn renderDebug(debug: DebugBatch, scene: *Scene) void {
    _ = scene;
    _ = debug;
}

pub fn renderHUD(batch: SpriteBatch, font: FontBatch, scene: *Scene) void {
    _ = batch;
    _ = scene;

    font.draw_text(-1920 / 2, -1080 / 2, "Emre Guneyler");
}
