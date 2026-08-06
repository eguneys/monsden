const SpriteBatch = @import("draw_spr.zig").SpriteBatch;

pub const Scene = struct {
    batch: SpriteBatch,

    const Self = @This();
    pub fn init(batch: SpriteBatch) Self {
        return .{ .batch = batch };
    }

    pub fn update(self: *Self, dt: f32) void {
        _ = self;
        _ = dt;
    }

    pub fn render(self: *Self) void {
        //self.batch.draw_bg(0, 0, 100, 100, 5, 5, 20, 20);

        //self.batch.draw_spr(0, 0, 20, 20, 50, 50, 2, 2);
        _ = self;
    }
};
