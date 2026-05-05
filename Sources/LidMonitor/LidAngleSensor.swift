import Foundation
import IOKit
import IOKit.hid
import OSLog

/// Reads the lid-angle HID sensor present on supported MacBooks
/// (Apple vendor ID, sensor usage page, custom lid-angle usage).
///
/// The sensor only emits HID reports while the hinge is moving, so the lid
/// would appear "frozen" if we relied on event callbacks alone. Instead we
/// pull the latest feature report on a polling timer.
@MainActor
final class LidAngleSensor {
    typealias AngleHandler = (Int) -> Void

    private let pollInterval: TimeInterval
    private let onAngle: AngleHandler

    private var manager: IOHIDManager?
    private var device: IOHIDDevice?
    private var pollTimer: Timer?

    init(pollInterval: TimeInterval = 0.5, onAngle: @escaping AngleHandler) {
        self.pollInterval = pollInterval
        self.onAngle = onAngle
    }

    deinit {
        pollTimer?.invalidate()
        if let manager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }
    }

    /// Opens the HID manager, finds the lid-angle device, and starts polling.
    /// No-op if the sensor isn't present (older MacBooks, Hackintoshes).
    func start() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(manager, Self.matchingCriteria as CFDictionary)

        let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard openResult == kIOReturnSuccess else {
            Logger.lidAngle.notice("HID manager open failed (\(openResult)); lid-angle disabled")
            return
        }
        self.manager = manager

        let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>
        guard let device = devices?.first else {
            Logger.lidAngle.notice("No lid-angle HID device matched on this Mac")
            return
        }
        self.device = device

        readNow()
        schedulePolling()
    }

    private func readNow() {
        guard let device else { return }
        var size = Self.reportBufferSize
        var report = [UInt8](repeating: 0, count: size)
        let status = IOHIDDeviceGetReport(
            device,
            kIOHIDReportTypeFeature,
            Self.reportID,
            &report,
            &size
        )
        guard status == kIOReturnSuccess, size >= 2 else { return }
        // Report layout: [reportID, angleDegrees, ...].
        onAngle(Int(report[1]))
    }

    private func schedulePolling() {
        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.readNow() }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    // MARK: - Constants

    private static let matchingCriteria: [String: Any] = [
        kIOHIDVendorIDKey:         appleVendorID,
        kIOHIDDeviceUsagePageKey:  sensorUsagePage,
        kIOHIDDeviceUsageKey:      lidAngleUsage,
    ]
    private static let appleVendorID    = 0x05AC
    private static let sensorUsagePage  = 0x20
    private static let lidAngleUsage    = 0x8A
    private static let reportID: CFIndex = 1
    private static let reportBufferSize = 8
}
