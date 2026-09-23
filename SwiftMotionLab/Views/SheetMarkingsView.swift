import SwiftUI

// This file draws the static paint on a sheet of curling ice — house rings, guide lines, and the
// hack — via `SheetMarkingsView` below `MarkingPalette`, the color set it draws with.

/// The house-ring and sheet-marking colors, switched as a set based on color scheme rather than
/// piecemeal at each drawing site — light mode reproduces the original bright-ice look exactly,
/// dark mode uses tints chosen to stay legible against the dark navy ice.
public struct MarkingPalette {
    /// Guide lines have to stay readable over two very different backdrops: the dark navy ice
    /// and the opaque white rings they cross. A pale cyan sits between the two — lighter than
    /// the ice, tinted enough to show against white — where plain white would vanish on the
    /// rings and the old low-opacity blue vanishes on the ice. Only used in dark mode; light mode
    /// keeps its original low-opacity blue.
    private static let guideLineColor = Color(red: 0.55, green: 0.78, blue: 0.92)

    private let _eightFootRing: Color
    private let _button: Color
    private let _centreLine: Color
    private let _teeLine: Color
    private let _hogLine: Color
    private let _hack: Color
    private let _sideLine: Color
    private let _playedSideLine: Color

    private init(eightFootRing: Color, button: Color, centreLine: Color, teeLine: Color, hogLine: Color, hack: Color, sideLine: Color, playedSideLine: Color) {
        _eightFootRing = eightFootRing
        _button = button
        _centreLine = centreLine
        _teeLine = teeLine
        _hogLine = hogLine
        _hack = hack
        _sideLine = sideLine
        _playedSideLine = playedSideLine
    }

    public var eightFootRing: Color { _eightFootRing }
    public var button: Color { _button }
    public var centreLine: Color { _centreLine }
    public var teeLine: Color { _teeLine }
    public var hogLine: Color { _hogLine }
    public var hack: Color { _hack }
    public var sideLine: Color { _sideLine }
    public var playedSideLine: Color { _playedSideLine }

    public static func current(for colorScheme: ColorScheme) -> MarkingPalette {
        switch colorScheme {
        case .dark:
            MarkingPalette(
                // A clearly blue-tinted fill (not just a darkened grey), so the ring still reads
                // as painted ice instead of a cutout back to a bright white backdrop.
                eightFootRing: Color(red: 0.55, green: 0.68, blue: 0.85),
                // The original light-blue tint, kept much closer to white than the 8-foot ring
                // so the button still reads as the brightest point in the house.
                button: Color(red: 0.90, green: 0.95, blue: 1.0),
                centreLine: guideLineColor.opacity(0.35),
                teeLine: guideLineColor.opacity(0.45),
                hogLine: guideLineColor.opacity(0.60),
                hack: Color(white: 0.82).opacity(0.50),
                sideLine: guideLineColor.opacity(0.20),
                playedSideLine: guideLineColor.opacity(0.55)
            )
        default:
            MarkingPalette(
                eightFootRing: .white,
                button: .white,
                centreLine: Color.blue.opacity(0.12),
                teeLine: Color.blue.opacity(0.18),
                hogLine: Color.blue.opacity(0.25),
                hack: Color.black.opacity(0.55),
                sideLine: Color.blue.opacity(0.12),
                playedSideLine: Color.blue.opacity(0.35)
            )
        }
    }
}

/// The static paint on one sheet of ice: house rings, centre/tee/hog lines, and the hack.
/// Shared by the played sheet (`CurlingSheetView`) and the faded neighbours drawn by
/// `MotionLabRinkView`, so the two always agree on what a sheet looks like.
public struct SheetMarkingsView: View {
    /// Scales every marking together, so a faded neighbouring sheet reads as one coherent line
    /// weight rather than each marking fading at its own rate.
    public var opacity: Double = 1

    @Environment(\.colorScheme) private var colorScheme

    public init(opacity: Double = 1) {
        self.opacity = opacity
    }

    public var body: some View {
        GeometryReader { proxy in
            let palette = MarkingPalette.current(for: colorScheme)
            let houseMargin: CGFloat = 12
            let houseCenterY = proxy.size.height * CurlingSheet.houseCenterY
            let hogLineY = proxy.size.height * CurlingSheet.hogLineY
            // A sheet can end up at aspect ratios far from the ideal 0.72 (the rink hands a
            // width-bound sheet its full available height in narrow layouts), so the outer ring's
            // radius is capped by whatever room is actually available above and below the tee, not
            // just by width.
            let outerRadius = min(
                proxy.size.width * CurlingSheet.houseOuterRadius,
                houseCenterY - houseMargin,
                hogLineY - houseCenterY - houseMargin
            )
            let outerDiameter = outerRadius * 2
            let eightFootDiameter = outerDiameter * 8 / 12
            let fourFootDiameter = outerDiameter * 4 / 12
            let buttonDiameter = outerDiameter / 12

            ZStack {
                // Curling house: four concentric painted rings around the tee.
                Circle()
                    .fill(Color.blue.opacity(0.35))
                    .frame(width: outerDiameter, height: outerDiameter)
                    .position(x: proxy.size.width * 0.5, y: houseCenterY)
                Circle()
                    .fill(palette.eightFootRing)
                    .frame(width: eightFootDiameter, height: eightFootDiameter)
                    .position(x: proxy.size.width * 0.5, y: houseCenterY)
                Circle()
                    .fill(Color.red.opacity(0.40))
                    .frame(width: fourFootDiameter, height: fourFootDiameter)
                    .position(x: proxy.size.width * 0.5, y: houseCenterY)
                Circle()
                    .fill(palette.button)
                    .frame(width: buttonDiameter, height: buttonDiameter)
                    .position(x: proxy.size.width * 0.5, y: houseCenterY)

                // Sheet markings: centre line, tee line, hog line, and the hack.
                Rectangle()
                    .fill(palette.centreLine)
                    .frame(width: 1, height: proxy.size.height)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.5)
                Rectangle()
                    .fill(palette.teeLine)
                    .frame(width: outerDiameter, height: 1)
                    .position(x: proxy.size.width * 0.5, y: houseCenterY)
                Rectangle()
                    .fill(palette.hogLine)
                    .frame(width: proxy.size.width, height: 3)
                    .position(x: proxy.size.width * 0.5, y: hogLineY)
                RoundedRectangle(cornerRadius: 3)
                    .fill(palette.hack)
                    .frame(width: 40, height: 8)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height * CurlingSheet.hackRestY + 30)
            }
            .opacity(opacity)
        }
    }
}
