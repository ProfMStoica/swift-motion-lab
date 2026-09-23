import SwiftUI

/// How the target stone struck by the delivery moves in the house.
public enum HouseAnimationStyle: String, CaseIterable, Identifiable
{
    case linear
    // MARK: Spring
    case spring
    case easeInOut
    case bouncy

    public var id: String { rawValue }

    //The title of the animation shown in the UI controls (labels, tuning panel, etc)
    public var title: String {
        switch self {
            case .linear: return "Linear"
            
            // MARK: Spring
            case .spring: return "Spring"
            
            case .easeInOut: return "Ease In-Out"
            
            case .bouncy: return "Bouncy"
        }
    }

    /// The description shown in the animation tuning panel, above the tuning controls
    public var description: String {
        switch self {
            case .linear:
                return "Uniform motion that feels flat and artificial."
            // MARK: Spring
            case .spring:
                return "Springy contact — the struck stone kicks away and wobbles to a stop."
            
            case .easeInOut:
                return "Smooth start and finish for a calm, natural delivery."
                
            case .bouncy:
                return "Extra rebound for a playful, exaggerated stone animation."
        }
    }

    /// Which of the pre-agreed tunables in `HouseParameter` the panel shows for this style, in
    /// order, from the catalog in `TuningValues.swift`. `ControlPanelView` renders a slider for each one listed here.
    public var parameters: [HouseParameter] {
        switch self {
            case .linear:
                return [.duration]
            
            // MARK: Spring
            case .spring:
                return [.mass, .stiffness, .damping]
                
            case .easeInOut:
                return [.duration]
                
            case .bouncy:
                return [.duration, .extraBounce]
        }
    }
}

/// Builds the SwiftUI animation for a delivery style at a given set of tuning values, and answers
/// how long it takes to play and when the delivered stone looks like it has arrived.
public struct HouseAnimator
{
    ///The current animation style to be used for the delivered stone
    private let _style: HouseAnimationStyle
    
    ///The corresponding parameter used in customizing the current animation style (e.g.duration for a linear animation)
    private let _tuning: HouseTuning
    
    /// The pause between contact and the house animation actually starting to play. Fixed rather
    /// than tunable, to keep the panel to the concepts the demo teaches.
    public static let startDelay: TimeInterval = 0.08
    
    public init(style: HouseAnimationStyle, tuning: HouseTuning) {
        _style = style
        _tuning = tuning
    }
    
    public var animation: Animation {
        let selectedAnimation: Animation
        
        switch _style {
            case .linear:
                selectedAnimation = .linear(duration: _tuning.duration)
            
            // MARK: Spring
            case .spring:
                selectedAnimation = .interpolatingSpring(mass: _tuning.mass, stiffness: _tuning.stiffness, damping: _tuning.damping)
                
            case .easeInOut:
                selectedAnimation = .easeInOut(duration: _tuning.duration)
                
            case .bouncy:
                selectedAnimation = .bouncy(duration: _tuning.duration, extraBounce: _tuning.extraBounce)
                
        }

        return selectedAnimation.delay(Self.startDelay)
    }

    /// How long this style's animation takes to play, `startDelay` included — a caller waits
    /// exactly this long and no more. A timing curve just reports its duration; a spring has no
    /// duration at all, so it reports its own settling estimate instead (see
    /// `Spring.settlingDuration`).
    public var playDuration: TimeInterval {
        let animationDuration: TimeInterval

        switch _style {
            case .linear:
                animationDuration = _tuning.duration
            
            // MARK: Spring
            case .spring:
                animationDuration = _tuning.spring.settlingDuration
                
            case .easeInOut:
                animationDuration = _tuning.duration
                
            case .bouncy:
                animationDuration = _tuning.duration
        }

        return animationDuration + Self.startDelay
    }
}
