import Combine
import Foundation

/// Top-level observable model surfaced to SwiftUI. Composes the individual
/// hardware monitors (`ClamshellMonitor`, `LidAngleSensor`) with `DimController`
/// and reacts to `Preferences` changes via Combine.
@MainActor
final class LidMonitor: ObservableObject {

    // MARK: - Published surface

    @Published private(set) var isClosed: Bool = false
    @Published private(set) var angleDegrees: Int?
    @Published private(set) var dimActive: Bool = false

    let preferences: Preferences

    // MARK: - Collaborators

    private var clamshell: ClamshellMonitor!
    private var lidAngle:  LidAngleSensor!
    private var dim:       DimController!
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Init

    convenience init() {
        self.init(preferences: Preferences())
    }

    init(preferences: Preferences) {
        self.preferences = preferences

        self.clamshell = ClamshellMonitor { [weak self] closed in
            self?.isClosed = closed
        }

        self.lidAngle = LidAngleSensor { [weak self] angle in
            self?.didReadAngle(angle)
        }

        self.dim = DimController(preferences: preferences) { [weak self] active in
            self?.dimActive = active
        }

        observePreferences()

        clamshell.start()
        lidAngle.start()
    }

    // MARK: - Internals

    private func didReadAngle(_ angle: Int) {
        if angle != angleDegrees {
            angleDegrees = angle
        }
        dim.evaluate(angle: angle)
    }

    private func observePreferences() {
        // Re-evaluate dim state when the threshold changes — the user may have
        // crossed the new boundary without the lid actually moving.
        preferences.$dimThreshold
            .dropFirst()
            .sink { [weak self] _ in
                guard let self, let angle = self.angleDegrees else { return }
                self.dim.evaluate(angle: angle)
            }
            .store(in: &subscriptions)

        // Push slider edits into the system immediately if we're already dimmed,
        // so the user gets live feedback while dragging.
        preferences.$dimVolume
            .dropFirst()
            .sink { [weak self] _ in self?.dim.reapplyVolume() }
            .store(in: &subscriptions)

        preferences.$dimBrightness
            .dropFirst()
            .sink { [weak self] _ in self?.dim.reapplyBrightness() }
            .store(in: &subscriptions)
    }
}
