const Scene = @import("scene.zig").Scene;

pub const GamePlatform = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        peekMessages: *const fn (ctx: *anyopaque) bool,
        toggleFullscreen: *const fn (ctx: *anyopaque) void,
        beginDraw: *const fn (ctx: *anyopaque) void,
        endDraw: *const fn (ctx: *anyopaque) void,
        onResize: *const fn (ctx: *anyopaque, new_width: u32, new_height: u32) void,
        deinit: *const fn (ctx: *anyopaque) void,
    };

    pub fn deinit(self: *Self) void {
        self.vtable.deinit(self.ptr);
    }

    const Self = @This();
    pub fn update(self: *Self) bool {
        const shouldQuit = self.vtable.peekMessages(self.ptr);

        return shouldQuit;
    }

    pub fn toggleFullscreen(self: *Self) void {
        self.vtable.toggleFullscreen(self.ptr);
    }

    pub fn beginDraw(self: *Self) void {
        self.vtable.beginDraw(self.ptr);
    }

    pub fn endDraw(self: *Self) void {
        self.vtable.endDraw(self.ptr);
    }

    pub fn onResize(self: *Self, new_width: u32, new_height: u32) void {
        self.vtable.onResize(self.ptr, new_width, new_height);
    }
};

pub const GameManager = struct {
    platform: GamePlatform,
    scene: Scene,

    const Self = @This();

    pub fn deinit(self: *Self) void {
        self.platform.deinit();
        //self.scene.deinit();
    }

    pub fn init(platform: GamePlatform, scene: Scene) Self {
        return .{ .platform = platform, .scene = scene };
    }

    pub fn update(self: *Self, dt: f32) bool {
        const shouldQuit = self.platform.update();
        if (shouldQuit) {
            return true;
        }
        self.scene.update(dt);
        return false;
    }

    pub fn render(self: *Self) void {
        self.platform.beginDraw();
        self.scene.render();
        self.platform.endDraw();
    }
};

pub const GameLoop = struct {
    running: bool,

    const Self = @This();

    pub fn init() Self {
        return .{ .running = true };
    }

    pub fn run(self: *Self, game: *GameManager) void {
        while (self.running) {
            const shouldQuit = game.update(0);

            if (shouldQuit) {
                self.running = false;
                break;
            }

            game.render();

            // sleep ? elapsed_time accumulator render alpha etc.
        }
    }
};
