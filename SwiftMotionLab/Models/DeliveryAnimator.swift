import SwiftUI

/// How the delivered stone is animated as it travels up the sheet.
public enum DeliveryAnimationStyle: String, CaseIterable, Identifiable
{
    case linear
    // MARK: Spring
    case spring

    public var id: String { rawValue }

    //The title of the animation shown in the UI controls (labels, tuning panel, etc)
    public var title: String {
        switch self {
            case .linear: return "Linear"
            // MARK: Spring
            case .spring: return "Spring"
        }
    }

    /// The description shown in the animation tuning panel, above the tuning controls
    public var description: String {
        switch self {
            case .linear:
                return "Uniform motion that feels flat and artificial."
            // MARK: Spring
            case .spring:
                return "A springy throw — mass, stiffness, and damping give the stone some life."
        }
    }

    /// Which of the pre-agreed tunables in `DeliveryParameter` the panel shows for this style, in
    /// order, from the catalog in `TuningValues.swift`. `ControlPanelView` renders a slider for each one listed here.
    public var parameters: [DeliveryParameter] {
        switch self {
            case .linear:
                return [.duration]
            // MARK: Spring
            case .spring:
                return [.mass, .stiffness, .damping]
        }
    }
}

/// Builds the SwiftUI animation for a delivery style at a given set of tuning values, and answers
/// how long it takes to play and when the delivered stone looks like it has arrived.
public struct DeliveryAnimator
{
    ///The current animation style to be used for the delivered stone
    private let _style: DeliveryAnimationStyle
    
    ///The corresponding parameter used in customizing the current animation style (e.g.duration for a linear animation)
    private let _tuning: DeliveryTuning
    
    /// How far into `playDuration` the house animation is triggered, for a curve that approaches
    /// its target monotonically — linear, or a spring damped at or past critical
    /// (`dampingRatio >= 1`, see `contactDelay`). 
    private static let monotonicContactFraction: Double = 0.82
    
    public init(style: DeliveryAnimationStyle, tuning: DeliveryTuning) {
        _style = style
        _tuning = tuning
    }
    
    public var animation: Animation {
        switch _style {
            case .linear:
                return .linear(duration: _tuning.duration)
            // MARK: Spring
            case .spring:
                return .interpolatingSpring(mass: _tuning.mass, stiffness: _tuning.stiffness, damping: _tuning.damping)
        }
    }

    /// How long this style's animation takes to play.
    public var playDuration: TimeInterval {
        switch _style {
            case .linear:
                return _tuning.duration
            // MARK: Spring
            case .spring:
                // A spring is never given a duration, so it reports its own settling estimate instead.
                return _tuning.spring.settlingDuration
        }
    }

    /// How long to wait, after release, before the house animation is triggered. Used to aproximate the physics of house stone being hit
    public var contactDelay: TimeInterval {
        switch _style {
            case .linear:
                return playDuration * Self.monotonicContactFraction
            // MARK: Spring
            case .spring:
                // Trigger contact the moment the spring first reaches its target, if it ever does
                // cleanly (see `timeToFirstReachingTarget`); otherwise fall back like `.linear`.
                return _tuning.spring.timeToFirstReachingTarget ?? playDuration * Self.monotonicContactFraction
        }
    }
}
