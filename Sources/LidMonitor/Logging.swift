import Foundation
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.blax.LidMonitor"

    static let clamshell      = Logger(subsystem: subsystem, category: "clamshell")
    static let lidAngle       = Logger(subsystem: subsystem, category: "lid-angle")
    static let dim            = Logger(subsystem: subsystem, category: "dim")
    static let systemControls = Logger(subsystem: subsystem, category: "system-controls")
    static let launchAtLogin  = Logger(subsystem: subsystem, category: "launch-at-login")
}
