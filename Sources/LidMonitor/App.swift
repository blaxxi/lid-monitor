import SwiftUI

@main
struct LidMonitorApp: App {
    @StateObject private var monitor = LidMonitor()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(monitor)
                .environmentObject(monitor.preferences)
        } label: {
            Image(systemName: monitor.isClosed ? "laptopcomputer.slash" : "laptopcomputer")
        }
        .menuBarExtraStyle(.window)
    }
}
