import Foundation
import OSLog

/// State machine that toggles "dim mode" — lowered volume + brightness, optional
/// media pause — when the lid drops below the user's configured threshold.
///
/// The original (pre-dim) volume and brightness are captured on entry and
/// restored on exit, so the user's normal levels survive a dim/restore cycle.
@MainActor
final class DimController {
    typealias ActiveHandler = (Bool) -> Void

    private let preferences: Preferences
    private let onChange: ActiveHandler

    private(set) var isActive: Bool = false
    private var savedVolume: Float?
    private var savedBrightness: Float?

    init(preferences: Preferences, onChange: @escaping ActiveHandler) {
        self.preferences = preferences
        self.onChange = onChange
    }

    /// Engages dim mode if `angle` is below the threshold; releases it otherwise.
    func evaluate(angle: Int) {
        if angle < preferences.dimThreshold {
            engage()
        } else {
            release()
        }
    }

    /// Push the current dim-volume into CoreAudio without changing dim state.
    /// Called when the user moves the volume slider while already dimmed.
    func reapplyVolume() {
        guard isActive else { return }
        SystemControls.setVolume(Float(preferences.dimVolume))
    }

    /// Push the current dim-brightness into DisplayServices without changing dim state.
    func reapplyBrightness() {
        guard isActive else { return }
        SystemControls.setBrightness(Float(preferences.dimBrightness))
    }

    private func engage() {
        guard !isActive else { return }
        savedVolume = SystemControls.getVolume()
        savedBrightness = SystemControls.getBrightness()
        SystemControls.setVolume(Float(preferences.dimVolume))
        SystemControls.setBrightness(Float(preferences.dimBrightness))
        if preferences.stopMediaOnDim {
            SystemControls.pauseMedia()
        }
        isActive = true
        Logger.dim.info("engaged (threshold \(self.preferences.dimThreshold)°)")
        onChange(true)
    }

    private func release() {
        guard isActive else { return }
        if let savedVolume     { SystemControls.setVolume(savedVolume) }
        if let savedBrightness { SystemControls.setBrightness(savedBrightness) }
        savedVolume = nil
        savedBrightness = nil
        isActive = false
        Logger.dim.info("released")
        onChange(false)
    }
}
