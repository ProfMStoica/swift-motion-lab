import SwiftUI

/// The full rink: the ice, the one sheet actually being played, and — on screens wide enough to
/// leave room beside it — faded neighbouring sheets that turn what would otherwise be dead space
/// into the impression of a busy club with several sheets in play at once.
public struct MotionLabRinkView: View {
    public let model: MotionLabViewModel
    /// When true, leftover width beside the played sheet is filled with faded neighbours instead
    /// of being left blank. Compact layouts pass false so the sheet takes the whole rink and stays
    /// aligned with the header text above it.
    public var showsNeighbouringSheets: Bool = false
    /// How dark the ice reads in dark mode. Light mode always uses the original bright-ice
    /// gradient regardless of this setting — see `ice(...)`. `dark50` is the only tone actually
    /// in use; `dark30`/`dark70` are kept defined below for future reference rather than deleted.
    public var iceTone: IceTone = .dark50

    @Environment(\.colorScheme) private var colorScheme

    public init(model: MotionLabViewModel, showsNeighbouringSheets: Bool = false, iceTone: IceTone = .dark50) {
        self.model = model
        self.showsNeighbouringSheets = showsNeighbouringSheets
        self.iceTone = iceTone
    }

    /// A mid-blue → dark-navy vertical gradient for dark-mode ice, at one of three brightness
    /// levels. Each case's name records how much darker its mean brightness is than the
    /// original light-blue-to-white ice (mean ≈ 0.99).
    public enum IceTone {
        case dark30, dark50, dark70

        public var gradient: LinearGradient {
            LinearGradient(colors: [topColor, bottomColor], startPoint: .top, endPoint: .bottom)
        }

        private var topColor: Color {
            switch self {
            case .dark30: Color(red: 0.48, green: 0.65, blue: 0.82)
            case .dark50: Color(red: 0.30, green: 0.46, blue: 0.62)
            case .dark70: Color(red: 0.17, green: 0.28, blue: 0.40)
            }
        }

        private var bottomColor: Color {
            switch self {
            case .dark30: Color(red: 0.25, green: 0.41, blue: 0.56)
            case .dark50: Color(red: 0.14, green: 0.26, blue: 0.38)
            case .dark70: Color(red: 0.06, green: 0.13, blue: 0.20)
            }
        }
    }

    /// The ice as it looked before dark-mode support: light blue fading to near white. Always
    /// used in light mode, independent of `iceTone`.
    private static let lightIceGradient = LinearGradient(
        colors: [Color(red: 0.80, green: 0.90, blue: 0.98), Color(red: 0.97, green: 0.99, blue: 1.0)],
        startPoint: .top,
        endPoint: .bottom
    )

    private static let maxNeighboursPerSide = 4

    public var body: some View {
        GeometryReader { proxy in
            let box = proxy.size
            // GeometryReader can propose a zero size during first layout (and in some preview
            // contexts); dividing by a zero sheet width below would produce an infinite neighbour
            // count and trap on the `Int` conversion.
            if box.width > 0 && box.height > 0 {
                rinkContent(in: box)
            }
        }
    }

    private func rinkContent(in box: CGSize) -> some View {
        // The played sheet always fills the box's full height: unlike leftover width, which
        // neighbours can absorb, leftover height has nowhere to go — sheets only ever tile
        // side by side, never stacked — so there is no case where shrinking the height to
        // preserve `sheetAspectRatio` buys anything but dead space above and below.
        //
        // `sheetAspectRatio` only comes into it for sizing width: fitting the sheet to the
        // box's height when neighbours are wanted, so they have some leftover width to fill.
        // With no neighbours to align with, the sheet is free to take the whole box — width
        // included — and `SheetMarkingsView` already adapts its ring sizing to whatever
        // aspect ratio it is handed.
        let sheetWidth = showsNeighbouringSheets ? fittedSheetWidth(in: box) : box.width
        let sheetHeight = box.height
        let hasLeftoverWidth = showsNeighbouringSheets && box.width > sheetWidth
        let rinkWidth = hasLeftoverWidth ? box.width : sheetWidth
        let rinkHeight = sheetHeight
        let centerX = box.width * 0.5
        let centerY = box.height * 0.5
        let gutter = max(0, (rinkWidth - sheetWidth) / 2)
        let neighbourCount = sheetWidth > 0
            ? min(Int(ceil(gutter / sheetWidth)), Self.maxNeighboursPerSide)
            : 0

        return ZStack {
            ice(rinkWidth: rinkWidth, rinkHeight: rinkHeight, sheetWidth: sheetWidth, neighbourCount: neighbourCount)
                .frame(width: rinkWidth, height: rinkHeight)
                .position(x: centerX, y: centerY)
                .clipShape(RoundedRectangle(cornerRadius: 28))

            CurlingSheetView(model: model)
                .frame(width: sheetWidth, height: sheetHeight)
                .position(x: centerX, y: centerY)
        }
    }

    /// The played sheet's width if it were fit to the box's full height at
    /// `CurlingSheet.aspectRatio`, capped at the box's own width. Capping matters: on a box
    /// narrower than that fit (a tall, narrow window), the ratio-derived width would overflow,
    /// and the sheet should fall back to simply filling the box's width instead — the same
    /// width-bound case `rinkContent` already handles by leaving `hasLeftoverWidth` false.
    private func fittedSheetWidth(in box: CGSize) -> CGFloat {
        min(box.width, box.height * CurlingSheet.aspectRatio)
    }

    private func ice(rinkWidth: CGFloat, rinkHeight: CGFloat, sheetWidth: CGFloat, neighbourCount: Int) -> some View {
        let isDark = colorScheme == .dark
        return ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(isDark ? iceTone.gradient : Self.lightIceGradient)
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(isDark ? Color.white.opacity(0.18) : Color.blue.opacity(0.15), lineWidth: 1)
                }

            if neighbourCount > 0 {
                neighbouringSheets(rinkWidth: rinkWidth, rinkHeight: rinkHeight, sheetWidth: sheetWidth, count: neighbourCount)
                sideLines(rinkWidth: rinkWidth, rinkHeight: rinkHeight, sheetWidth: sheetWidth, neighbourCount: neighbourCount)
                // Lifts the played sheet's ice very slightly above its neighbours so it reads as
                // the active one even before the stone or targets are noticed.
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: sheetWidth, height: rinkHeight)
                    .position(x: rinkWidth * 0.5, y: rinkHeight * 0.5)
            }

            VStack {
                HStack {
                    Label(model.statusMessage, systemImage: "sparkles")
                        .font(.footnote.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                }
                Spacer()
            }
            .padding(16)
        }
    }

    private func neighbouringSheets(rinkWidth: CGFloat, rinkHeight: CGFloat, sheetWidth: CGFloat, count: Int) -> some View {
        ZStack {
            ForEach(-count...count, id: \.self) { offset in
                if offset != 0 {
                    SheetMarkingsView(opacity: 0.28)
                        .frame(width: sheetWidth, height: rinkHeight)
                        .position(x: rinkWidth * 0.5 + sheetWidth * CGFloat(offset), y: rinkHeight * 0.5)
                }
            }
        }
        // Sheets that get cut off at the rink's edge fade into the ice instead of ending at a hard
        // line, so the rink reads as one continuous surface rather than a strip of cutouts.
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white, location: 0.18),
                    .init(color: .white, location: 0.82),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private func sideLines(rinkWidth: CGFloat, rinkHeight: CGFloat, sheetWidth: CGFloat, neighbourCount: Int) -> some View {
        // One boundary between every pair of adjacent sheets, including the two flanking the
        // played sheet at ±0.5 sheet-widths from centre — those get drawn stronger below.
        let palette = MarkingPalette.current(for: colorScheme)
        let boundaryOffsets = (0...(2 * neighbourCount + 1)).map { CGFloat($0) - CGFloat(neighbourCount) - 0.5 }
        return ForEach(boundaryOffsets, id: \.self) { offset in
            let isPlayedSheetEdge = abs(offset) == 0.5
            Rectangle()
                .fill(isPlayedSheetEdge ? palette.playedSideLine : palette.sideLine)
                .frame(width: isPlayedSheetEdge ? 2 : 1, height: rinkHeight)
                .position(x: rinkWidth * 0.5 + sheetWidth * offset, y: rinkHeight * 0.5)
        }
    }
}
