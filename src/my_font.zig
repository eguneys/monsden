const Allocator = @import("std").mem.Allocator;
const win32 = @import("win32/zigwin32/win32.zig");

const HRESULT = win32.zig.HRESULT;

const IDWriteFactory = win32.graphics.direct_write.IDWriteFactory;
const IDWriteFontFace = win32.graphics.direct_write.IDWriteFontFace;
const DWriteCreateFactory = win32.dwrite.DWriteCreateFactory;
const IDWriteFontFile = win32.graphics.direct_write.IDWriteFontFile;
const DWRITE_GLYPH_RUN = win32.graphics.direct_write.DWRITE_GLYPH_RUN;

const IDWriteGlyphRunAnalysis = win32.graphics.direct_write.IDWriteGlyphRunAnalysis;
const DWRITE_GLYPH_METRICS = win32.graphics.direct_write.DWRITE_GLYPH_METRICS;
const DWRITE_FONT_METRICS = win32.graphics.direct_write.DWRITE_FONT_METRICS;

const RECT = win32.foundation.RECT;

const IID_IDWriteFactory = win32.graphics.direct_write.IID_IDWriteFactory;

pub const MyFontFactory = struct {
    dwrite_factory: *IDWriteFactory,
    font_face: *IDWriteFontFace,

    const Self = @This();
    pub fn deinit(self: *Self) void {
        self.dwrite_factory.IUnknown.Release();
        self.font_face.IUnknown.Release();
    }

    pub fn init(font_path_w: [*:0]const u16) !MyFontFactory {
        var dwrite_factory: ?*IDWriteFactory = null;

        var hr = DWriteCreateFactory(
            .SHARED,
            IID_IDWriteFactory,
            @ptrCast(&dwrite_factory),
        );
        if (hr != HRESULT.S_OK) return error.FailedCreateWicFactory;
        errdefer _ = dwrite_factory.?.IUnknown.Release();

        var font_file: *IDWriteFontFile = undefined;

        hr = dwrite_factory.?.CreateFontFileReference(
            font_path_w,
            null,
            &font_file,
        );
        if (hr != HRESULT.S_OK) return error.FailedCreateFontFileReference;
        defer _ = font_file.IUnknown.Release();

        var font_face: *IDWriteFontFace = undefined;

        hr = dwrite_factory.?.CreateFontFace(
            .TRUETYPE,
            1,
            @ptrCast(&font_file),
            0,
            .{},
            &font_face,
        );
        if (hr != HRESULT.S_OK) return error.FailedCreateFontFace;
        errdefer _ = font_face.IUnknown.Release();

        return .{ .dwrite_factory = dwrite_factory.?, .font_face = font_face };
    }

    pub fn alphaBufferForOneGlyphRun(self: *Self, allocator: Allocator, font_size_px: f32, glyph_index: usize, baseline_x: f32, baseline_y: f32) !struct { buf: []u8, w: u32, h: u32 } {
        var advance: f32 = 0.0; // single glpyph, no advance needed for its own analysis
        const glyph_run = DWRITE_GLYPH_RUN{
            .fontFace = self.font_face,
            .fontEmSize = font_size_px,
            .glyphCount = 1,
            .glyphIndices = @ptrCast(&glyph_index),
            .glyphAdvances = &advance,
            .glyphOffsets = null,
            .isSideways = 0,
            .bidiLevel = 0,
        };

        var analysis: ?*IDWriteGlyphRunAnalysis = null;
        var hr = self.dwrite_factory.CreateGlyphRunAnalysis(
            &glyph_run,
            1.0,
            null,
            .GDI_CLASSIC,
            .NATURAL,
            baseline_x,
            baseline_y,
            @ptrCast(&analysis),
        );
        if (hr != HRESULT.S_OK) return error.FailedCreateGlyphRun;
        defer _ = analysis.?.IUnknown.Release();

        var bounds: RECT = undefined;
        hr = analysis.?.GetAlphaTextureBounds(.ALIASED_1x1, &bounds);
        if (hr != HRESULT.S_OK) return error.FailedGetAlphaTextureBounds;

        const w: u32 = @intCast(bounds.right - bounds.left);
        const h: u32 = @intCast(bounds.bottom - bounds.top);
        const buf = try allocator.alloc(u8, w * h);
        errdefer allocator.free(buf);

        hr = analysis.?.CreateAlphaTexture(
            .ALIASED_1x1,
            &bounds,
            @ptrCast(buf.ptr),
            @intCast(buf.len),
        );
        if (hr != HRESULT.S_OK) return error.FailedCreateAlphaTexture;
        // buf is now w * h single-byte alpha coverage, ready to copy into your atlas

        return .{ .buf = buf, .w = w, .h = h };
    }

    pub fn GetGlyphIndices(self: *Self, font_size_px: f32, codepoints: []const u32, glyph_indices: []u16, advances: []f32, bearings_x: []i32, bearings_y: []i32) !void {
        var hr = self.font_face.GetGlyphIndices(
            codepoints.ptr,
            @intCast(codepoints.len),

            @ptrCast(glyph_indices.ptr),
        );
        if (hr != HRESULT.S_OK) return error.FailedGetGlyphIndices;
        var design_metrics: [256]DWRITE_GLYPH_METRICS = undefined;
        hr = self.font_face.GetDesignGlyphMetrics(
            @ptrCast(glyph_indices.ptr),
            @intCast(glyph_indices.len),
            &design_metrics,
            0,
        );
        if (hr != HRESULT.S_OK) return error.FailedGetDesignGlyphMetrics;

        var font_metrics: DWRITE_FONT_METRICS = undefined;
        self.font_face.GetMetrics(&font_metrics);

        const scale = font_size_px / @as(f32, @floatFromInt(font_metrics.designUnitsPerEm));

        for (0..codepoints.len) |i| {
            advances[i] = @as(f32, @floatFromInt(design_metrics[i].advanceWidth)) * scale;
            bearings_x[i] = design_metrics[i].leftSideBearing;
            bearings_y[i] = design_metrics[i].topSideBearing;
        }
    }
};
