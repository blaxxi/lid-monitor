import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var monitor: LidMonitor

    var body: some View {
        VStack(spacing: 14) {
            AngleHero()

            if monitor.dimActive {
                DimBadge(threshold: monitor.preferences.dimThreshold)
                    .transition(.scale.combined(with: .opacity))
            }

            SettingsCard()
        }
        .padding(18)
        .frame(width: 300)
        .background(AmbientGlow())
        .animation(.smooth(duration: 0.25), value: monitor.dimActive)
    }
}

private struct AmbientGlow: View {
    var body: some View {
        ZStack {
            blob(color: Color(red: 0.45, green: 0.35, blue: 1.00), opacity: 0.30, radius: 60, x: -90, y: -110)
            blob(color: Color(red: 0.20, green: 0.80, blue: 0.95), opacity: 0.22, radius: 70, x: 110, y: 60)
            blob(color: Color(red: 1.00, green: 0.40, blue: 0.65), opacity: 0.18, radius: 70, x: 60,  y: 160)
        }
        .allowsHitTesting(false)
    }

    private func blob(color: Color, opacity: Double, radius: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(opacity))
            .blur(radius: radius)
            .offset(x: x, y: y)
    }
}
