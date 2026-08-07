const Self = @This();
position: [2]f32,
zoom: f32,
// rotation: f32

pub fn init(x: f32, y: f32) Self {
    return .{ .position = .{ x, y }, .zoom = 1 };
}

pub fn viewProjectionMatrix(self: Self, viewport_width: f32, viewport_height: f32) [16]f32 {
    // world units visible across the viewport at current zoom
    const view_w = viewport_width / self.zoom;
    const view_h = viewport_height / self.zoom;

    const sx = 2.0 / view_w;
    const sy = -2.0 / view_h;

    // translate so camera.position is centered in the view
    const tx = -self.position[0] * sx;
    const ty = -self.position[1] * sy;

    return [16]f32{
        sx,  0.0, 0.0, 0.0,
        0.0, sy,  0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        tx,  ty,  0.0, 1.0,
    };
}
