atlas_width: u32,
atlas_height: u32,
cursor_x: u32 = 0,
cursor_y: u32 = 0, // top of current shelf
shelf_height: u32 = 0, // tallest glyph placed on current shelf so far

const Self = @This();

pub fn allocate(self: *Self, w: u32, h: u32) ?XY {
    if (self.cursor_x + w > self.atlas_width) {
        self.cursor_y += self.shelf_height;
        self.cursor_x = 0;
        self.shelf_height = 0;
    }

    if (self.cursor_y + h > self.atlas_height) {
        return null;
    }

    const pos: XY = .{ .x = self.cursor_x, .y = self.cursor_y };
    self.cursor_x += w;
    self.shelf_height = @max(self.shelf_height, h);
    return pos;
}

pub const XY = struct { x: u32, y: u32 };
