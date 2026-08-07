const Self = @This();
position: [2]f32,
zoom: f32,
// rotation: f32

pub fn init(x: f32, y: f32) Self {
    return .{ .position = .{ x, y }, .zoom = 1 };
}

pub fn viewProjectionMatrix(self: Self, viewport_width: f32, viewport_height: f32) [16]f32 {
    const scale = 1.0 / self.zoom;

    const aspect = viewport_width / viewport_height;

    // Create orthographic projection matrix (column-major)
    // [ 2/(width*scale)    0             0    -translation_x ]
    // [      0         2/(height*scale)  0    -translation_y ]
    // [      0             0             1          0        ]
    // [      0             0             0          1        ]

    // width and height of the view in world space
    const view_w = 2.0 * scale * aspect;
    const view_h = 2.0 * scale;

    // translate so the camera position is at the center
    const tx = -self.position[0] / (view_w / 2.0);
    const ty = -self.position[1] / (view_h / 2.0);

    // column-major matrix
    return [16]f32{
        2.0 / view_w, 0.0,          0.0, 0.0,
        0.0,          2.0 / view_h, 0.0, 0.0,
        0.0,          0.0,          1.0, 0.0,
        tx,           ty,           0.0, 1.0,
    };
}
