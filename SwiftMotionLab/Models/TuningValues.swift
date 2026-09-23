import SwiftUI

/// What the Delivery section can tune. Each animation style keeps its own copy, so switching
/// styles in the picker never throws away tuning you already did — a style simply never shows a
/// slider for a value it does not use.
public struct DeliveryTuning {
    private var _duration: Double = 1.0          // linear
    // Claimed only by `spring`'s `.mass`/`.stiffness`/`.damping` parameters (see `DeliveryParameter`).
    private var _mass: Double = 1.0               // spring
    private var _stiffness: Double = 120          // spring
    private var _damping: Double = 12             // spring

    public init() {}

    public var duration: Double {
        get { _duration }
        set { _duration = newValue }
    }

    public var mass: Double {
        get { _mass }
        set { _mass = newValue }
    }

    public var stiffness: Double {
        get { _stiffness }
        set { _stiffness = newValue }
    }

    public var damping: Double {
        get { _damping }
        set { _damping = newValue }
    }
}

/// What the House Animation section can tune. Deliberately the same shape as `DeliveryTuning` for
/// the spring fields — same kind of physics, a separate copy, so tuning one phase never moves the
/// other.
public struct HouseTuning {
    // Deliberately slower than Delivery's default duration (1.0), not just matching it: the house
    // stone now travels a random path (`houseExitDistance`), so it needs more time than a short
    // knock-back did to stay watchable rather than a blur.
    private var _duration: Double = 1.4          // linear
    // Claimed only by `bouncy`'s `.extraBounce` parameter (see `HouseParameter.extraBounce`).
    private var _extraBounce: Double = 0.3        // bouncy
    // Claimed only by `spring`'s `.mass`/`.stiffness`/`.damping` parameters (see `HouseParameter`).
    private var _mass: Double = 1.0               // spring
    private var _stiffness: Double = 120          // spring
    private var _damping: Double = 12             // spring

    public init() {}

    public var duration: Double {
        get { _duration }
        set { _duration = newValue }
    }

    public var extraBounce: Double {
        get { _extraBounce }
        set { _extraBounce = newValue }
    }

    public var mass: Double {
        get { _mass }
        set { _mass = newValue }
    }

    public var stiffness: Double {
        get { _stiffness }
        set { _stiffness = newValue }
    }

    public var damping: Double {
        get { _damping }
        set { _damping = newValue }
    }
}

/// One tunable the panel knows how to render: what to call it, where the value lives, and the
/// range the slider spans. `ControlPanelView` generates its House sliders from whichever of these
/// the selected style's `parameters` lists (see `HouseAnimationStyle.parameters`).
public struct HouseParameter: Identifiable {
    private let _title: String
    private let _keyPath: WritableKeyPath<HouseTuning, Double>
    private let _range: ClosedRange<Double>
    private let _caption: String?

    public init(title: String, keyPath: WritableKeyPath<HouseTuning, Double>, range: ClosedRange<Double>, caption: String? = nil) {
        _title = title
        _keyPath = keyPath
        _range = range
        _caption = caption
    }

    public var title: String { _title }
    public var keyPath: WritableKeyPath<HouseTuning, Double> { _keyPath }
    public var range: ClosedRange<Double> { _range }
    public var caption: String? { _caption }
    public var id: String { _title }
}

///House tuning parameters
extension HouseParameter {
    public static let duration = HouseParameter(title: "Animation Duration", keyPath: \.duration, range: 0.2...1.5)
    public static let extraBounce = HouseParameter(title: "Extra Bounce", keyPath: \.extraBounce, range: 0...0.6)
    public static let mass = HouseParameter(title: "Mass", keyPath: \.mass, range: 0.1...10, caption: "How heavy the stone feels.")
    public static let stiffness = HouseParameter(title: "Stiffness", keyPath: \.stiffness, range: 1...300, caption: "How strongly the spring pulls back to rest.")
    public static let damping = HouseParameter(title: "Damping", keyPath: \.damping, range: 1...50, caption: "How quickly the wobble fades away.")
}

/// Delivery turning parameters
public struct DeliveryParameter: Identifiable {
    private let _title: String
    private let _keyPath: WritableKeyPath<DeliveryTuning, Double>
    private let _range: ClosedRange<Double>
    private let _caption: String?

    public init(title: String, keyPath: WritableKeyPath<DeliveryTuning, Double>, range: ClosedRange<Double>, caption: String? = nil) {
        _title = title
        _keyPath = keyPath
        _range = range
        _caption = caption
    }

    public var title: String { _title }
    public var keyPath: WritableKeyPath<DeliveryTuning, Double> { _keyPath }
    public var range: ClosedRange<Double> { _range }
    public var caption: String? { _caption }
    public var id: String { _title }
}

extension DeliveryParameter {
    public static let duration = DeliveryParameter(title: "Duration", keyPath: \.duration, range: 0.25...2.0)
    public static let mass = DeliveryParameter(title: "Mass", keyPath: \.mass, range: 0.1...10, caption: "How heavy the stone feels.")
    public static let stiffness = DeliveryParameter(title: "Stiffness", keyPath: \.stiffness, range: 1...300, caption: "How strongly the spring pulls back to rest.")
    public static let damping = DeliveryParameter(title: "Damping", keyPath: \.damping, range: 1...50, caption: "How quickly the wobble fades away.")
}

// MARK: Spring

/// Tuning values that describe a damped spring. Both `DeliveryTuning` and `HouseTuning` satisfy
/// this, which is what lets one spring-timing implementation serve the throw and the hit alike.
public protocol SpringTunable {
    var mass: Double { get }
    var stiffness: Double { get }
    var damping: Double { get }
}

extension SpringTunable {
    /// The spring these values describe. `allowOverDamping: true` so a heavily damped combination
    /// reports its real behaviour instead of being silently clamped to critical.
    public var spring: Spring {
        Spring(mass: mass, stiffness: stiffness, damping: damping, allowOverDamping: true)
    }
}

extension DeliveryTuning: SpringTunable {}
extension HouseTuning: SpringTunable {}

extension Spring {
    /// When this spring first reaches its target, before any overshoot — the moment a collision
    /// driven by it looks like it has landed. `nil` when critically damped or beyond
    /// (`dampingRatio >= 1`): such a spring approaches its target without ever crossing it, so
    /// there is no such moment, and the caller should fall back to a fraction of the play
    /// duration instead.
    ///
    /// `settlingDuration` answers a different question — when the spring stops *moving*, long
    /// after it first arrives — and SwiftUI has no query for arrival, so this solves the damped
    /// step response `x(t) = 1 - e^(-ζωn·t)(cos ωd·t + (ζ/√(1-ζ²))·sin ωd·t)` for its first root
    /// at `x = 1`.
    public var timeToFirstReachingTarget: TimeInterval? {
        guard dampingRatio < 1 else { return nil }
        let naturalFrequency = (stiffness / mass).squareRoot()
        let dampedFrequency = naturalFrequency * (1 - dampingRatio * dampingRatio).squareRoot()
        return (Double.pi - acos(dampingRatio)) / dampedFrequency
    }
}
