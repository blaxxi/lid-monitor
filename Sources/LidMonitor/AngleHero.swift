import SwiftUI

/// Big gradient angle readout with a circular quit button on the trailing edge.
struct AngleHero: View {
    @EnvironmentObject private var monitor: LidMonitor

    var body: some View {
        HStack(spacing: 10) {
            angleLabel
            Spacer()
            QuitButton()
        }
    }

    @ViewBuilder
    private var angleLabel: some View {
        if let angle = monitor.angleDegrees {
            Text("\(angle)°")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.primary)
                .contentTransition(.numericText())
                .animation(.smooth(duration: 0.25), value: angle)
        } else {
            Text("—")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

private struct QuitButton: View {
    var body: some View {
        Button {
            NSApp.terminate(nil)
        } label: {
            Image(systemName: "power")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Theme.glassBorder, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .keyboardShortcut("q")
        .help("Quit")
    }
}
