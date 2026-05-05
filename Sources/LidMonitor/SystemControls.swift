import AudioToolbox
import CoreAudio
import CoreGraphics
import Foundation
import OSLog

/// Thin wrappers around CoreAudio + the private DisplayServices and MediaRemote
/// frameworks. Each call returns a Bool/optional so callers can decide whether
/// a missing entry point matters; logging happens here so call sites stay terse.
enum SystemControls {

    // MARK: - Volume (CoreAudio)

    static func getVolume() -> Float? {
        guard let device = defaultOutputDeviceID else { return nil }
        var value: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        var address = volumeAddress
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value)
        guard status == noErr else {
            Logger.systemControls.error("getVolume failed: \(status)")
            return nil
        }
        return value
    }

    @discardableResult
    static func setVolume(_ value: Float) -> Bool {
        guard let device = defaultOutputDeviceID else { return false }
        var clamped = value.clamped(to: 0...1)
        var address = volumeAddress
        let status = AudioObjectSetPropertyData(
            device,
            &address,
            0, nil,
            UInt32(MemoryLayout<Float32>.size),
            &clamped
        )
        if status != noErr {
            Logger.systemControls.error("setVolume failed: \(status)")
        }
        return status == noErr
    }

    private static var defaultOutputDeviceID: AudioDeviceID? {
        var id = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &id
        )
        return (status == noErr && id != kAudioObjectUnknown) ? id : nil
    }

    private static var volumeAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
    )

    // MARK: - Brightness (DisplayServices, private)

    static func getBrightness() -> Float? {
        guard let fn = DisplayServices.getBrightness else { return nil }
        var value: Float = 0
        return fn(CGMainDisplayID(), &value) == 0 ? value : nil
    }

    @discardableResult
    static func setBrightness(_ value: Float) -> Bool {
        guard let fn = DisplayServices.setBrightness else { return false }
        return fn(CGMainDisplayID(), value.clamped(to: 0...1)) == 0
    }

    // MARK: - Media (MediaRemote, private)

    /// Pauses any currently-playing media. No-op if nothing is playing or the
    /// MediaRemote framework is unavailable on this system.
    @discardableResult
    static func pauseMedia() -> Bool {
        guard let send = MediaRemote.sendCommand else { return false }
        return send(MediaRemote.Command.pause, nil)
    }
}

// MARK: - DisplayServices binding

private enum DisplayServices {
    typealias Get = @convention(c) (UInt32, UnsafeMutablePointer<Float>) -> Int32
    typealias Set = @convention(c) (UInt32, Float) -> Int32

    static let getBrightness: Get? = symbol("DisplayServicesGetBrightness")
    static let setBrightness: Set? = symbol("DisplayServicesSetBrightness")

    private static let handle: UnsafeMutableRawPointer? = dlopen(
        "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices",
        RTLD_LAZY
    )

    private static func symbol<T>(_ name: String) -> T? {
        guard let handle, let raw = dlsym(handle, name) else {
            Logger.systemControls.warning("DisplayServices: \(name) unavailable")
            return nil
        }
        return unsafeBitCast(raw, to: T.self)
    }
}

// MARK: - MediaRemote binding

private enum MediaRemote {
    typealias SendCommand = @convention(c) (Int32, CFDictionary?) -> Bool

    enum Command {
        // MRMediaRemoteCommand enum values (private API).
        static let pause: Int32 = 1
    }

    static let sendCommand: SendCommand? = {
        guard let handle, let raw = dlsym(handle, "MRMediaRemoteSendCommand") else {
            Logger.systemControls.warning("MediaRemote: MRMediaRemoteSendCommand unavailable")
            return nil
        }
        return unsafeBitCast(raw, to: SendCommand.self)
    }()

    private static let handle: UnsafeMutableRawPointer? = dlopen(
        "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
        RTLD_LAZY
    )
}

// MARK: - Helpers

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
