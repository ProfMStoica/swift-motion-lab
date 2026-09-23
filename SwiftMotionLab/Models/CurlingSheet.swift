import SwiftUI

/// One sheet of curling ice: its fixed dimensions, the geometry its markings are painted to, and
/// the target stones currently standing on it. Everything about *where things are* lives here —
/// the view model owns what is happening on the sheet, not where the lines are drawn.
public struct CurlingSheet {
    /// The hack — where a delivered stone rests before and after a flick.
    public static let hackRestY: CGFloat = 0.88
    
    /// The centre line — every delivery starts and ends on it.
    public static let centerLineX: CGFloat = 0.5
    
    /// Where a delivered stone sits before and after a throw.
    public static let hackRestPosition = CGPoint(x: centerLineX, y: hackRestY)
    
    /// The hog line. A stone that fails to cross it has been hogged.
    public static let hogLineY: CGFloat = 0.62
    
    /// The far edge of play; also the cap on how far any flick can carry.
    public static let houseTopY: CGFloat = 0.08
    
    /// Width ÷ height of one played sheet.
    public static let aspectRatio: CGFloat = 0.72
    
    /// Vertical centre of the house (the tee), in normalized sheet coordinates.
    public static let houseCenterY: CGFloat = 0.28
    
    /// Radius of the twelve-foot ring, in x-normalized units (fractions of sheet width). Matches
    /// the `width * 0.39` used to paint the outer ring in `SheetMarkingsView`.
    public static let houseOuterRadius: CGFloat = 0.39
    
    /// How far back or forward a stone may be moved by hand before release.
    public static let dragBand: ClosedRange<CGFloat> = 0.78...0.94
    
    /// A stone's fixed on-screen size. Positions are normalized to sheet size, but a stone isn't,
    /// so keeping stones apart (and inside the rings) needs an assumed sheet width.
    public static let stoneDiameter: CGFloat = 48
    
    /// The narrowest a played sheet is expected to get. Because `aspectRatio` makes the sheet
    /// tall, the binding constraint on width is usually available *height*, not device width — a
    /// short window (an iPhone rotated to landscape, a squat Mac window) can leave the sheet no
    /// wider than this even though it has plenty of horizontal room. Assuming a narrow width here,
    /// rather than a typical one, means a roomier layout only ever gives the generator more
    /// clearance than it planned for, never less — the direction that would let stones overlap.
    public static let nominalSheetWidth: CGFloat = 220

    private static let palette: [Color] = [.orange, .blue, .mint, .purple, .pink, .green, .yellow, .cyan]

    private var _stones: [Stone]

    public init(stones: [Stone]? = nil) {
        _stones = stones ?? Self.makeStones()
    }

    public var stones: [Stone] {
        get { _stones }
        set { _stones = newValue }
    }

    public var isEmpty: Bool {
        !stones.contains(where: \.isVisible)
    }

    /// The first visible target stone standing at or above `stopY` — i.e. the nearest one a
    /// delivery stopping there would have swept past. `nil` means the stone stopped short of
    /// every target stone.
    public func firstStoneInPath(stoppingAt stopY: CGFloat) -> Int? {
        stones.indices
            .filter { stones[$0].isVisible && stones[$0].position.y >= stopY }
            .max { stones[$0].position.y < stones[$1].position.y }
    }

    /// Sets out a fresh house: 3-5 stones scattered inside the rings, none of them overlapping
    /// and every one of them reachable by a full-power delivery.
    public static func makeStones() -> [Stone] {
        let count = Int.random(in: 3...5)
        let colors = palette.shuffled()
        // A stone's centre must stay `stoneDiameter / 2` inside the ring, or the granite itself
        // would poke outside the twelve-foot line.
        let maxRadius = houseOuterRadius - (stoneDiameter / 2) / nominalSheetWidth
        // Two centres closer than one stone width, plus a sliver of daylight, would visibly
        // overlap.
        let minSeparation = (stoneDiameter / nominalSheetWidth) * 1.1
        // Anything above this line can never be swept by a delivery — `deliverStone(stoppingAt:)`
        // clamps travel at `houseTopY` — and would strand the house short of ever emptying.
        let minReachableY = houseTopY + 0.02

        // `nominalSheetWidth`'s conservative (narrow) guess makes `minSeparation` a large slice of
        // the placement disc, so 200 attempts is generous headroom for 3 stones and merely likely
        // to fall short of 5 on the narrowest sheets — in which case fewer stones is the correct
        // outcome, not a bug: it means 5 genuinely non-overlapping stones would not have fit.
        var positions: [CGPoint] = []
        var attempts = 0
        while positions.count < count && attempts < 200 {
            attempts += 1
            // Uniform sampling over a disc needs the sqrt, or candidates bunch near the centre.
            let radius = maxRadius * CGFloat.random(in: 0...1).squareRoot()
            let angle = CGFloat.random(in: 0..<(2 * .pi))
            let x = centerLineX + radius * cos(angle)
            // A circle on screen is an ellipse in normalized coordinates: one x-unit spans
            // `aspectRatio` y-units.
            let y = houseCenterY + radius * sin(angle) * aspectRatio
            guard y >= minReachableY else { continue }

            let fitsWithExisting = positions.allSatisfy { existing in
                let dx = x - existing.x
                let dy = (y - existing.y) / aspectRatio
                return (dx * dx + dy * dy).squareRoot() >= minSeparation
            }
            guard fitsWithExisting else { continue }

            positions.append(CGPoint(x: x, y: y))
        }

        return zip(positions, colors).map { position, color in
            Stone(position: position, color: color)
        }
    }
}
