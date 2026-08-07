const std = @import("std");
const IntegerBitSet = std.bit_set.IntegerBitSet;
const Self = @This();

const KeyboardState = @import("loop.zig").KeyboardState;

keymappings: [256]?Action = .{null} ** 256,

action_is_just_down: IntegerBitSet(64) = .empty,
action_is_just_up: IntegerBitSet(64) = .empty,
action_is_down: IntegerBitSet(64) = .empty,

pub const Action = enum {
    Run_Left,
    Run_Right,
    Jump_Up,
    Quit,
};

pub const ActionSign = enum {
    Up,
    Just_Down,
    Just_Up,
    Down,
};

pub fn add_keymapping(self: *Self, key: usize, action: Action) void {
    self.keymappings[key] = action;
}

pub fn is_just_down(self: *const Self, action: Action) bool {
    return self.action_is_just_down.isSet(@intFromEnum(action));
}
pub fn is_just_up(self: *const Self, action: Action) bool {
    return self.action_is_just_up.isSet(@intFromEnum(action));
}
pub fn is_down(self: *const Self, action: Action) bool {
    return self.action_is_down.isSet(@intFromEnum(action));
}

pub fn getActionSign(self: *const Self, action: Action) ActionSign {
    if (self.is_just_down(action)) return ActionSign.Just_Down;
    if (self.is_just_up(action)) return ActionSign.Just_Up;
    if (self.is_down(action)) return ActionSign.Down;
    return ActionSign.Up;
}

pub fn onDown(self: *Self, key: usize) void {
    if (self.keymappings[key]) |action| {
        if (self.is_down(action)) return;
        self.action_is_just_down.set(@intFromEnum(action));
    }
}
pub fn onUp(self: *Self, key: usize) void {
    if (self.keymappings[key]) |action| {
        self.action_is_just_up.set(@intFromEnum(action));
    }
}

pub fn update(self: *const Self) void {
    var it = self.action_is_just_down.iterator();
    while (it.next()) |action_down| {
        self.action_is_down.set(action_down);
    }

    var it2 = self.action_is_just_up.iterator();
    while (it2.next()) |action_up| {
        self.action_is_down.unset(action_up);
    }

    self.action_is_just_down = .empty;
    self.action_is_just_up = .empty;
}

pub fn SyncWithKeyboardState(self: *Self, keyboard: *const KeyboardState) void {
    for (0..256) |vk| {
        if (self.keymappings[vk] != null) {
            if (keyboard.justPressed(vk)) {
                self.onDown(vk);
            }
            if (keyboard.justReleased(vk)) {
                self.onUp(vk);
            }
            if (keyboard.isHeld(vk)) {
                self.onDown(vk);
            }
        }
    }
}
