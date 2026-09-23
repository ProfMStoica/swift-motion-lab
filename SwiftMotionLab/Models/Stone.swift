import SwiftUI

/// Represents a curling stone delivered or hit on teh ice sheet: the position, visibility, and animatable properties (scale, opacity,
/// rotation) shared by every target stone and the delivered stone alike. `StoneView` renders it;
public struct Stone: Identifiable, Equatable {
    /// What a stone looks like before anything animates it, and what `resetHouse()` puts it back to.
    public enum Rest {
        public static let scale: CGFloat = 1
        public static let opacity: Double = 1
        public static let rotation: Angle = .zero
    }

    private let _id: UUID
    
    private let _color: Color
    
    private var _position: CGPoint
    
    private var _isVisible: Bool
    
    private var _scale: CGFloat
    
    private var _opacity: Double
    
    private var _rotation: Angle

    public init(id: UUID = UUID(), position: CGPoint, color: Color) {
        _id = id
        _color = color
        _position = position
        _isVisible = true
        _scale = Rest.scale
        _opacity = Rest.opacity
        _rotation = Rest.rotation
    }

    public var id: UUID { _id }

    /// Get-only: a stone's colour is fixed at placement. Only the animatable properties below are
    /// ever written.
    public var color: Color { _color }

    public var position: CGPoint {
        get { _position }
        set { _position = newValue }
    }

    public var isVisible: Bool {
        get { _isVisible }
        set { _isVisible = newValue }
    }

    public var scale: CGFloat {
        get { _scale }
        set { _scale = newValue }
    }

    public var opacity: Double {
        get { _opacity }
        set { _opacity = newValue }
    }

    public var rotation: Angle {
        get { _rotation }
        set { _rotation = newValue }
    }
}
