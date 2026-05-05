import SwiftUI

/// Pill that appears while dim mode is active, telling the user why the lights went down.
struct DimBadge: View {
    let threshold: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "moon.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 11))
            Text("Dimmed below \(threshold)°")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .background(Capsule().fill(.orange.opacity(0.18)))
        .overlay(Capsule().stroke(Theme.dimAccent, lineWidth: 0.6))
    }
}
