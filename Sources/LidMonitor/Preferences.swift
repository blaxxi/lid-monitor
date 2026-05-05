import Foundation

/// User-tweakable settings persisted in `UserDefaults`.
///
/// The model is intentionally dumb: it just mirrors values to disk. Side-effects
/// triggered by changes (re-evaluating dim mode, pushing new volume to CoreAudio)
/// live in `LidMonitor`, which observes this object via Combine.
@MainActor
final class Preferences: ObservableObject {

    // MARK: - Published state

    @Published var dimThreshold: Int = Defaults.dimThreshold {
        didSet { defaults.set(dimThreshold, forKey: Key.dimThreshold) }
    }

    @Published var dimVolume: Double = Defaults.dimVolume {
        didSet { defaults.set(dimVolume, forKey: Key.dimVolume) }
    }

    @Published var dimBrightness: Double = Defaults.dimBrightness {
        didSet { defaults.set(dimBrightness, forKey: Key.dimBrightness) }
    }

    @Published var stopMediaOnDim: Bool = Defaults.stopMediaOnDim {
        didSet { defaults.set(stopMediaOnDim, forKey: Key.stopMediaOnDim) }
    }

    // MARK: - Bounds

    nonisolated static let thresholdRange: ClosedRange<Int> = 5...90
    nonisolated static let thresholdStep = 5

    // MARK: - Init

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Note: assigning the property's initial value in init does not trigger didSet,
        // so this load path doesn't write back to UserDefaults.
        self.dimThreshold   = defaults.read(Key.dimThreshold,   default: Defaults.dimThreshold)
        self.dimVolume      = defaults.read(Key.dimVolume,      default: Defaults.dimVolume)
        self.dimBrightness  = defaults.read(Key.dimBrightness,  default: Defaults.dimBrightness)
        self.stopMediaOnDim = defaults.read(Key.stopMediaOnDim, default: Defaults.stopMediaOnDim)
    }

    // MARK: - Constants

    private enum Key {
        static let dimThreshold   = "dimThreshold"
        static let dimVolume      = "dimVolume"
        static let dimBrightness  = "dimBrightness"
        static let stopMediaOnDim = "stopMediaOnDim"
    }

    private enum Defaults {
        static let dimThreshold   = 30
        static let dimVolume      = 0.10
        static let dimBrightness  = 0.10
        static let stopMediaOnDim = true
    }
}

private extension UserDefaults {
    func read<Value>(_ key: String, default defaultValue: Value) -> Value {
        (object(forKey: key) as? Value) ?? defaultValue
    }
}
