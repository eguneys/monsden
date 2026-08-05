const std = @import("std");
const win32 = @import("win32/zigwin32/win32.zig");

const IWICImagingFactory = win32.graphics.imaging.IWICImagingFactory;
const CoCreateInstance = win32.ole32.CoCreateInstance;
const CLSID_WICImagingFactory = win32.graphics.imaging.CLSID_WICImagingFactory;
const CLSCTX_INPROC_SERVER = win32.system.com.CLSCTX_INPROC_SERVER;
const IID_IWICImagingFactory = win32.graphics.imaging.IID_IWICImagingFactory;

const HRESULT = win32.zig.HRESULT;
const GENERIC_READ = win32.system.system_services.GENERIC_READ;

const IWICBitmapDecoder = win32.graphics.imaging.IWICBitmapDecoder;
const IWICBitmapFrameDecode = win32.graphics.imaging.IWICBitmapFrameDecode;
const IWICFormatConverter = win32.graphics.imaging.IWICFormatConverter;

const WICDecodeMetadataCacheOnDemand = win32.graphics.imaging.WICDecodeMetadataCacheOnDemand;

const GUID_WICPixelFormat32bppRGBA = win32.graphics.imaging.GUID_WICPixelFormat32bppRGBA;
const WICBitmapDitherTypeNone = win32.graphics.imaging.WICBitmapDitherTypeNone;
const WICBitmapPaletteTypeCustom = win32.graphics.imaging.WICBitmapPaletteTypeCustom;

const CoInitializeEx = win32.ole32.CoInitializeEx;
const COINIT_APARTMENTTHREADED = win32.system.com.COINIT_APARTMENTTHREADED;

pub fn MyComInitialize() !void {
    const hr = CoInitializeEx(null, COINIT_APARTMENTTHREADED);
    if (hr != HRESULT.S_OK) return error.FailedInitCom;
}

pub const MyWicFactory = struct {
    wic_factory: *IWICImagingFactory,

    const Self = @This();
    pub fn deinit(self: *Self) void {
        _ = self.wic_factory.IUnknown.Release();
    }

    pub fn init() !MyWicFactory {
        var wic_factory: *IWICImagingFactory = undefined;

        const hr = CoCreateInstance(
            &CLSID_WICImagingFactory,
            null,
            CLSCTX_INPROC_SERVER,
            IID_IWICImagingFactory,
            @ptrCast(&wic_factory),
        );
        if (hr != HRESULT.S_OK) return error.FailedCreateWicFactory;

        return .{ .wic_factory = wic_factory };
    }

    pub fn png(self: *MyWicFactory, lpath: [*:0]const u16, pixels: []u8) ![]u8 {
        var decoder: *IWICBitmapDecoder = undefined;

        var hr = self.wic_factory.CreateDecoderFromFilename(
            lpath,
            null,
            GENERIC_READ,
            WICDecodeMetadataCacheOnDemand,
            @ptrCast(&decoder),
        );
        if (hr != HRESULT.S_OK) return error.FailedCreateDecoder;
        defer _ = decoder.IUnknown.Release();

        var frame: *IWICBitmapFrameDecode = undefined;
        hr = decoder.GetFrame(0, @ptrCast(&frame));
        if (hr != HRESULT.S_OK) return error.FailedGetFrame;
        defer _ = frame.IUnknown.Release();

        var converter: *IWICFormatConverter = undefined;
        hr = self.wic_factory.CreateFormatConverter(@ptrCast(&converter));
        if (hr != HRESULT.S_OK) return error.FailedCreateFormatConverter;
        defer _ = converter.IUnknown.Release();

        var dstFormat = GUID_WICPixelFormat32bppRGBA;

        hr = converter.Initialize(
            &frame.IWICBitmapSource,
            &dstFormat,
            WICBitmapDitherTypeNone,
            null,
            0.0,
            WICBitmapPaletteTypeCustom,
        );
        if (hr != HRESULT.S_OK) return error.FailedConverterInitialize;

        var width: u32 = undefined;
        var height: u32 = undefined;

        hr = converter.IWICBitmapSource.GetSize(&width, &height);
        if (hr != HRESULT.S_OK) return error.FailedGetSize;

        const stride = width * 4;

        hr = converter.IWICBitmapSource.CopyPixels(
            null,
            stride,
            width * height * 4,
            @ptrCast(pixels),
        );
        if (hr != HRESULT.S_OK) return error.FailedCopyPixels;

        return pixels[0 .. width * height * 4];
    }
};
