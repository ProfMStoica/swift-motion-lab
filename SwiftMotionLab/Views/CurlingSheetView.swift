import SwiftUI

/// One played sheet: the house, the target stones standing on it, and the delivered stone. Always
/// fills whatever frame it is given at `CurlingSheet.aspectRatio` — sizing the sheet
/// within a wider rink, and filling any leftover width with faded neighbours, is
/// `MotionLabRinkView`'s job.
public struct CurlingSheetView: View {
    public let model: MotionLabViewModel

    public init(model: MotionLabViewModel) {
        self.model = model
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                ZStack {
                    SheetMarkingsView()

                    // MARK: - Extension point: where target stone state becomes pixels
                    //
                    // Each animatable property on Stone is read here as a view modifier. An
                    // animation that needs something the model does not have yet (a blur, a glow, a
                    // border width) means adding the property to Stone and applying it here.
                    ForEach(model.sheet.stones.filter(\.isVisible)) { stone in
                        StoneView(stone: stone)
                            .position(x: proxy.size.width * stone.position.x,
                                      y: proxy.size.height * stone.position.y)
                    }

                    DeliveredStoneView(model: model, proxy: proxy)
                }
                // Bounds the delivered stone and the target stones to this sheet, so an animation
                // that ever exits toward `position.x` 0 or 1 — this sheet's own edges — would
                // disappear at the side line instead of sliding visibly across a neighbouring sheet.
                .clipShape(Rectangle())

                // Sits outside the sheet's own clip: the stone rests close enough to the bottom
                // edge that a gap below it has no room inside the sheet, so the hint is allowed to
                // spill into the rink's margin below instead.
                //
                // Matches the status label's default (primary) foreground rather than
                // `.secondary` — secondary text loses too much contrast against the translucent
                // material on dark ice.
                //
                // Pinned to the hack's fixed resting Y, not `model.deliveredStone.position.y`: this hint only
                // ever shows while the stone is at rest, so anchoring it to the live, animating
                // position instead of the constant would make it visibly ride along with the stone
                // during a flick's travel or a weak flick's spring-back to the hack.
                if !model.isDeliveringStone && !model.isDraggingStone {
                    Label(model.deliveryMethod.deliverPrompt, systemImage: model.deliveryMethod.promptSymbol)
                        .font(.footnote)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.opacity)
                        .position(
                            x: proxy.size.width * 0.5,
                            y: proxy.size.height * CurlingSheet.hackRestY + 62
                        )
                }
            }
        }
    }
}
