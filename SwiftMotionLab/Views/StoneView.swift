import SwiftUI

/// One piece of granite — a target stone already standing in the house, or the delivered stone
/// the player controls. Positioning and any gestures are the caller's job — this view only
/// renders the granite and applies the stone's own animatable properties.
public struct StoneView: View {
    /// Shared by every piece of granite on the sheet — target stones and the delivered stone — so
    /// they always read as the same material.
    private static let graniteGradient = RadialGradient(
        colors: [Color(white: 0.62), Color(white: 0.32), Color(white: 0.16)],
        center: UnitPoint(x: 0.35, y: 0.32),
        startRadius: 1,
        endRadius: 32
    )

    public let stone: Stone
    public var diameter: CGFloat = CurlingSheet.stoneDiameter
    public var shadowRadius: CGFloat = 12

    public init(stone: Stone, diameter: CGFloat = CurlingSheet.stoneDiameter, shadowRadius: CGFloat = 12) {
        self.stone = stone
        self.diameter = diameter
        self.shadowRadius = shadowRadius
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(Self.graniteGradient)
            Capsule()
                .fill(stone.color.gradient)
                .frame(width: diameter / 6, height: diameter * 0.45)
            Circle()
                .fill(stone.color.gradient)
                .frame(width: diameter * 0.205, height: diameter * 0.205)
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(stone.scale)
        .rotationEffect(stone.rotation)
        .opacity(stone.opacity)
        .shadow(color: .black.opacity(0.22), radius: shadowRadius, y: 4)
    }
}
