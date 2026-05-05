import SwiftUI

/// Stack of settings rows. All bindings flow into `Preferences`; persistence
/// happens there, side-effects are wired up in `LidMonitor`.
struct SettingsCard: View {
    @EnvironmentObject private var preferences: Preferences

    var body: some View {
        VStack(spacing: 14) {
            ThresholdRow(value: $preferences.dimThreshold)

            SliderRow(
                title: "Volume",
                systemImage: "speaker.wave.2.fill",
                value: $preferences.dimVolume
            )

            SliderRow(
                title: "Brightness",
                systemImage: "sun.max.fill",
                value: $preferences.dimBrightness
            )

            ToggleRow(
                title: "Pause media",
                systemImage: "pause.circle.fill",
                value: $preferences.stopMediaOnDim
            )

            ToggleRow(
                title: "Launch at login",
                systemImage: "power.circle.fill",
                value: Binding(
                    get: { LaunchAtLogin.isEnabled },
                    set: { LaunchAtLogin.isEnabled = $0 }
                )
            )
        }
    }
}

// MARK: - Rows

private struct ThresholdRow: View {
    @Binding var value: Int

    var body: some View {
        SettingsRow(systemImage: "bolt.fill", title: "Trigger") {
            HStack(spacing: 0) {
                StepButton(symbol: "minus", action: decrement)
                Text("\(value)°")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 38)
                    .contentTransition(.numericText())
                    .animation(.smooth(duration: 0.2), value: value)
                StepButton(symbol: "plus", action: increment)
            }
            .background(.ultraThinMaterial, in: stepperShape)
            .overlay(stepperShape.stroke(.white.opacity(0.18), lineWidth: 0.5))
        }
    }

    private var stepperShape: some InsettableShape {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
    }

    private func decrement() {
        value = max(Preferences.thresholdRange.lowerBound, value - Preferences.thresholdStep)
    }

    private func increment() {
        value = min(Preferences.thresholdRange.upperBound, value + Preferences.thresholdStep)
    }
}

private struct SliderRow: View {
    let title: String
    let systemImage: String
    @Binding var value: Double

    var body: some View {
        VStack(spacing: 5) {
            SettingsRow(systemImage: systemImage, title: title) {
                Text("\(Int((value * 100).rounded()))%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.smooth(duration: 0.15), value: value)
            }
            Slider(value: $value, in: 0...1)
                .controlSize(.small)
                .tint(Theme.primaryHorizontal)
        }
    }
}

private struct ToggleRow: View {
    let title: String
    let systemImage: String
    @Binding var value: Bool

    var body: some View {
        SettingsRow(systemImage: systemImage, title: title) {
            Toggle("", isOn: $value)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
    }
}

// MARK: - Shared row chrome

private struct SettingsRow<Trailing: View>: View {
    let systemImage: String
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            trailing()
        }
    }
}

private struct StepButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .bold))
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
}
