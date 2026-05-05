import Foundation
import IOKit
import IOKit.pwr_mgt
import OSLog

/// Observes `IOPMrootDomain`'s `AppleClamshellState` and fires a callback whenever
/// the lid open/closed state may have changed. Lifetime of the IOKit handles is
/// tied to this object; deinit releases them.
@MainActor
final class ClamshellMonitor {
    typealias StateHandler = (Bool) -> Void

    private let onChange: StateHandler
    private var rootDomain: io_service_t = 0
    private var notificationPort: IONotificationPortRef?
    private var notification: io_object_t = 0

    init(onChange: @escaping StateHandler) {
        self.onChange = onChange
    }

    deinit {
        if notification != 0 { IOObjectRelease(notification) }
        if rootDomain != 0 { IOObjectRelease(rootDomain) }
        if let notificationPort { IONotificationPortDestroy(notificationPort) }
    }

    /// Connects to IOPMrootDomain and arms the change notification. Safe to call once.
    func start() {
        rootDomain = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPMrootDomain")
        )
        guard rootDomain != 0 else {
            Logger.clamshell.error("IOPMrootDomain unavailable; lid state will not update")
            return
        }

        // Emit an initial reading so the UI doesn't sit on a stale default.
        onChange(currentState())

        let port = IONotificationPortCreate(kIOMainPortDefault)
        notificationPort = port
        guard let port else { return }
        IONotificationPortSetDispatchQueue(port, .main)

        let context = Unmanaged.passUnretained(self).toOpaque()
        IOServiceAddInterestNotification(
            port,
            rootDomain,
            kIOGeneralInterest,
            { context, _, _, _ in
                guard let context else { return }
                let monitor = Unmanaged<ClamshellMonitor>.fromOpaque(context).takeUnretainedValue()
                Task { @MainActor in
                    monitor.onChange(monitor.currentState())
                }
            },
            context,
            &notification
        )
    }

    private func currentState() -> Bool {
        guard rootDomain != 0,
              let raw = IORegistryEntryCreateCFProperty(
                rootDomain,
                Self.clamshellKey,
                kCFAllocatorDefault,
                0
              )
        else { return false }
        return (raw.takeRetainedValue() as? Bool) ?? false
    }

    private static let clamshellKey = "AppleClamshellState" as CFString
}
