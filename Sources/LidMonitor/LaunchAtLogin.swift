import Foundation
import OSLog
import ServiceManagement

/// Wrapper around `SMAppService.mainApp` so views can read/write a single Bool.
/// Failures are logged rather than thrown; the toggle silently snaps back on
/// the next render if the OS rejected the change (e.g. user denied in Settings).
enum LaunchAtLogin {
    static var isEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                let service = SMAppService.mainApp
                switch (newValue, service.status) {
                case (true, .enabled), (false, .notRegistered), (false, .notFound):
                    return
                case (true, _):
                    try service.register()
                case (false, _):
                    try service.unregister()
                }
            } catch {
                Logger.launchAtLogin.error("toggle failed: \(error.localizedDescription)")
            }
        }
    }
}
