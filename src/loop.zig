const std = @import("std");
const Io = std.Io;

const Camera = @import("camera.zig");

const Input = @import("input.zig");

const scn = @import("scene.zig");
const SpriteBatch = @import("draw_spr.zig").SpriteBatch;
const DebugBatch = @import("draw_spr.zig").DebugBatch;

pub const KeyboardState = struct {
    current: [256]bool = [_]bool{false} ** 256,
    previous: [256]bool = [_]bool{false} ** 256,

    pub fn init() KeyboardState {
        return .{};
    }

    pub fn snapshot(self: *KeyboardState) void {
        self.previous = self.current;
    }

    pub fn killFocus(self: *KeyboardState) void {
        self.current = [_]bool{false} ** 256;
    }

    pub fn justPressed(self: *const KeyboardState, vk: usize) bool {
        return self.current[vk] and !self.previous[vk];
    }
    pub fn justReleased(self: *const KeyboardState, vk: usize) bool {
        return !self.current[vk] and self.previous[vk];
    }
    pub fn isHeld(self: *const KeyboardState, vk: usize) bool {
        return self.current[vk];
    }
};

pub const GamePlatform = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        peekMessages: *const fn (ctx: *anyopaque) bool,
        toggleFullscreen: *const fn (ctx: *anyopaque) void,
        beginDraw: *const fn (ctx: *anyopaque, camera: Camera) void,
        endDraw: *const fn (ctx: *anyopaque) void,
        onResize: *const fn (ctx: *anyopaque, new_width: u32, new_height: u32) void,
        deinit: *const fn (ctx: *anyopaque) void,
        spriteBatch: *const fn (ctx: *anyopaque) SpriteBatch,
        debugBatch: *const fn (ctx: *anyopaque) DebugBatch,

        beginDebugDraw: *const fn (ctx: *anyopaque) void,
        endDebugDraw: *const fn (ctx: *anyopaque) void,

        beginSpriteDraw: *const fn (ctx: *anyopaque) void,
        endSpriteDraw: *const fn (ctx: *anyopaque) void,

        onKeyboardSnapshot: *const fn (ctx: *anyopaque) void,
        onKeyDown: *const fn (ctx: *anyopaque, vk: usize) void,
        onKeyUp: *const fn (ctx: *anyopaque, vk: usize) void,
        onKillFocus: *const fn (ctx: *anyopaque) void,

        addInputMappings: *const fn (ctx: *const anyopaque, input: *Input) void,
        keyboardState: *const fn (ctx: *anyopaque) *KeyboardState,
    };

    pub fn deinit(self: *Self) void {
        self.vtable.deinit(self.ptr);
    }

    const Self = @This();
    pub fn update(self: *Self) bool {
        self.vtable.onKeyboardSnapshot(self.ptr);
        const shouldQuit = self.vtable.peekMessages(self.ptr);

        return shouldQuit;
    }

    pub fn debugBatch(self: *Self) DebugBatch {
        return self.vtable.debugBatch(self.ptr);
    }

    pub fn spriteBatch(self: *Self) SpriteBatch {
        return self.vtable.spriteBatch(self.ptr);
    }

    pub fn toggleFullscreen(self: *Self) void {
        self.vtable.toggleFullscreen(self.ptr);
    }

    pub fn beginDraw(self: *Self, camera: Camera) void {
        self.vtable.beginDraw(self.ptr, camera);
    }

    pub fn endDraw(self: *Self) void {
        self.vtable.endDraw(self.ptr);
    }

    pub fn beginSpriteDraw(self: *Self) void {
        self.vtable.beginSpriteDraw(self.ptr);
    }

    pub fn endSpriteDraw(self: *Self) void {
        self.vtable.endSpriteDraw(self.ptr);
    }

    pub fn beginDebugDraw(self: *Self) void {
        self.vtable.beginDebugDraw(self.ptr);
    }

    pub fn endDebugDraw(self: *Self) void {
        self.vtable.endDebugDraw(self.ptr);
    }

    pub fn onResize(self: *Self, new_width: u32, new_height: u32) void {
        self.vtable.onResize(self.ptr, new_width, new_height);
    }

    pub fn onKeyboardSnapshot(self: *Self) void {
        self.vtable.onKeyboardSnapshot(self.ptr);
    }
    pub fn onKeyboardDown(self: *Self, vk: usize) void {
        self.vtable.onKeyDown(self.ptr, vk);
    }

    pub fn onKeyboardUp(self: *Self, vk: usize) void {
        self.vtable.onKeyUp(self.ptr, vk);
    }

    pub fn onKillFocus(self: *Self) void {
        self.vtable.onKillFocus(self.ptr);
    }

    pub fn addInputMappings(self: *const Self, input: *Input) void {
        self.vtable.addInputMappings(self.ptr, input);
    }

    pub fn keyboardState(self: *Self) *KeyboardState {
        return self.vtable.keyboardState(self.ptr);
    }
};

pub const GameManager = struct {
    platform: GamePlatform,
    scene: scn.Scene,
    input: Input,

    const Self = @This();

    pub fn deinit(self: *Self) void {
        self.platform.deinit();
        //self.scene.deinit();
    }

    pub fn init(platform: GamePlatform) Self {
        var input: Input = .{};
        platform.addInputMappings(&input);
        return .{
            .platform = platform,
            .scene = .init(),
            .input = input,
        };
    }

    pub fn update(self: *Self, dt: f64) bool {
        const shouldQuit = self.platform.update();
        if (shouldQuit) {
            return true;
        }

        self.input.SyncWithKeyboardState(self.platform.keyboardState());

        if (self.input.is_just_down(Input.Action.Quit)) {
            return true;
        }
        scn.updateScene(&self.scene, dt);
        return false;
    }

    pub fn render(self: *Self, alpha: f32) void {
        self.platform.beginDraw(self.scene.camera);

        self.platform.beginSpriteDraw();
        scn.renderScene(self.platform.spriteBatch(), &self.scene, alpha);
        self.platform.endSpriteDraw();

        self.platform.beginDebugDraw();
        scn.renderDebug(self.platform.debugBatch(), &self.scene);
        self.platform.endDebugDraw();

        self.platform.endDraw();
    }
};

pub const GameLoop = struct {
    io: Io,
    running: bool,

    const Self = @This();

    pub fn init(io: Io) Self {
        return .{ .io = io, .running = true };
    }

    pub fn run(self: *Self, game: *GameManager) void {
        const fixed_dt: f64 = 1.0 / 60.0; // 60 updates per second
        const max_frame_time: f64 = 0.25; // Prevents "spiral of death" if window is dragged

        //var timer = std.time.Timer.start() catch unreachable;
        //var last_time: u64 = timer.read();

        var last_time = Io.Clock.real.now(self.io);
        var accumulator: f64 = 0.0;

        while (self.running) {
            const current_time = Io.Clock.real.now(self.io);
            const frame_time_ns = Io.Timestamp.durationTo(last_time, current_time).toNanoseconds();
            last_time = current_time;

            // Convert nanoseconds to seconds, capped to avoid huge spikes
            var frame_time: f64 = @as(f64, @floatFromInt(frame_time_ns)) / 1_000_000_000.0;
            if (frame_time > max_frame_time) {
                frame_time = max_frame_time;
            }

            accumulator += frame_time;

            // 1. Fixed update loop (runs zero, one, or multiple times per frame)
            while (accumulator >= fixed_dt) {
                // If GameManager needs to return quit status from updates:
                const shouldQuit = game.update(fixed_dt); // pass fixed_dt if needed, or constant ticks
                if (shouldQuit) {
                    self.running = false;
                    break;
                }
                accumulator -= fixed_dt;
            }

            if (!self.running) break;

            // 2. Calculate interpolation alpha for smooth rendering
            // (how far we are into the *next* fixed step, from 0.0 to 1.0)
            const alpha = @as(f32, @floatCast(accumulator / fixed_dt));

            // 3. Render using alpha to smooth out the frame rate mismatch
            game.render(alpha);

            // 4. Optional yield / sleep to prevent 100% CPU usage if vsync is off
            // (Or rely on your windowing/renderer's internal vsync/swapbuffers limit)
            //std.time.sleep(1 * std.time.ns_per_ms);
        }
    }
};
