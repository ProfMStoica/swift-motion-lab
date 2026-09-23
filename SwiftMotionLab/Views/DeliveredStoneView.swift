import SwiftUI

/// The red stone the player controls: tap to deliver at full power, or in Flick mode, drag back
/// for a run-up and flick to deliver. Owns both gestures and its accessibility action, since
/// delivering the stone is the only thing this view can trigger.
public struct DeliveredStoneView: View {
    public let model: MotionLabViewModel
    public let proxy: GeometryProxy

    public init(model: MotionLabViewModel, proxy: GeometryProxy) {
        self.model = model
        self.proxy = proxy
    }

    /// The delivered stone's fixed on-screen size — bigger than a target stone's
    /// `CurlingSheet.stoneDiameter`, so the player's stone always reads as the one in play.
    private static let diameter: CGFloat = 54
    /// How much the stone grows while it is being dragged, as a purely visual cue independent of
    /// any animation style.
    private static let draggingScale: CGFloat = 1.06

    // MARK: - Extension point: the stone's only triggers are these two gestures
    //
    // `.contentShape` and `.gesture` must come before `.position`, not after: `.position()`
    // returns a view that fills all available space with the child placed inside it, so
    // attaching the gesture afterward would make the entire sheet draggable instead of just
    // the stone.
    public var body: some View {
        StoneView(stone: model.deliveredStone,
                  diameter: Self.diameter,
                  shadowRadius: model.isDraggingStone ? 18 : 12)
        .scaleEffect(model.isDraggingStone ? Self.draggingScale : 1)
        .animation(.snappy(duration: 0.2), value: model.isDraggingStone)
        .frame(width: 88, height: 88)
        .contentShape(Circle())
        // Both gestures are always attached; `isEnabled` toggles which one is live, rather than an
        // `if` swapping the modifier in and out — an `if` would change view identity and interrupt
        // any in-flight delivery animation the moment `deliveryMethod` changes.
        .gesture(TapGesture().onEnded { model.deliverStone() },
                 isEnabled: model.deliveryMethod == .tap)
        .gesture(flickGesture, isEnabled: model.deliveryMethod == .flick)
        .accessibilityElement()
        .accessibilityLabel("Stone")
        .accessibilityHint(model.deliveryMethod.accessibilityHint)
        .accessibilityAction(named: "Launch") { model.deliverStone() }
        .position(x: proxy.size.width * model.deliveredStone.position.x,
                  y: proxy.size.height * model.deliveredStone.position.y)
    }

    /// Flick mode's trigger: drag back for a run-up, release with upward velocity to throw.
    private var flickGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { model.dragStone(byNormalizedOffset: $0.translation.height / proxy.size.height) }
            .onEnded { model.releaseStone(normalizedVelocityY: $0.velocity.height / proxy.size.height) }
    }
}
