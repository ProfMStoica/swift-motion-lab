import SwiftUI
import Observation

/// Owns everything happening on the sheet right now: the delivered stone, the house of target
/// stones, the selected animation styles and their per-style tuning, and the status message. The
/// delivery sequence — triggering a throw, waiting out its timing, reacting to a hit — lives here
/// too, but the animations themselves do not: building the `Animation` for a style is
/// `DeliveryAnimator` / `HouseAnimator`'s job, not this class's.
@Observable
public final class MotionLabViewModel {
    /// How a delivery is triggered — separate from `DeliveryAnimationStyle`, which decides how the
    /// stone moves once triggered. This enum answers "what starts the throw," not "what curve
    /// carries it," so it never appears in `DeliveryAnimator` and adding a case here never touches
    /// that file.
    public enum LaunchMethod: String, CaseIterable, Identifiable {
        case tap
        case flick
        
        public var id: String { rawValue }
        
        public var title: String {
            switch self {
                case .tap: return "Tap"
                case .flick: return "Flick"
            }
        }
        
        /// Descrioption of actions in the tuning panel
        public var description: String {
            switch self {
                case .tap:
                    return "Delivers at full power every time. Use this to compare animation styles — identical travel distance means the curve is the only thing that changed."
                case .flick:
                    return "Drag back and flick up — more fun on a real device, and you can hog a stone. Each throw travels a different distance, so it's not for comparing styles."
            }
        }
        
        /// The idle hint shown on the sheet before a delivery starts.
        public var deliverPrompt: String {
            switch self {
                case .tap: return "Tap the stone to deliver"
                case .flick: return "Flick the stone to deliver"
            }
        }
        
        /// Symbol paired with `deliverPrompt`.
        public var promptSymbol: String {
            switch self {
                case .tap: return "hand.tap"
                case .flick: return "hand.draw"
            }
        }
        
        public var accessibilityHint: String {
            switch self {
                case .tap: return "Double-tap to deliver the stone"
                case .flick: return "Flick up to deliver the stone"
            }
        }
        
        /// Shown once the house is empty and idle, naming whichever action actually resets it in
        /// this method — mirrors `deliverPrompt`'s per-method wording.
        public var houseEmptyPrompt: String {
            switch self {
                case .tap: return "Tap the stone to set out a fresh house."
                case .flick: return "Flick through the house to reset the sheet."
            }
        }
    }
    
    /// Rejects taps and stray touches only — judging a weak throw is the hog line's job.
    private static let minimumFlickVelocity: CGFloat = 0.1
    
    /// How far the struck stone flies, in a random direction, before it fades. Deliberately
    /// *not* sized to guarantee leaving the sheet — the interesting part of a curve, especially a
    /// spring's overshoot and ring-down, is only worth showing if it's still on screen. This is
    /// sized instead so the *whole* path — approach, overshoot, any wobble-back — stays inside the
    /// sheet's `[0, 1]` bounds for most starting positions and directions. "Most," not "all": the
    /// house's own placement disc reaches close enough to the sheet's edges (see
    /// `CurlingSheet.houseOuterRadius`) that a stone ejected straight toward whichever edge it's
    /// already closest to can still clip.
    private static let houseExitDistance: CGFloat = 0.4
    
    /// The struck stone's fixed fade-out, once the tuned animation has played. Deliberately not
    /// tunable — see `applyHouseAnimation(to:)` for why it sits on its own curve.
    private static let fadeOutDuration: Double = 0.3
    
    /// How much the struck stone grows during its animation. Fixed rather than tunable, for the
    /// same reason as `HouseAnimator.startDelay`: it applies identically to every house style and
    /// adds nothing to the room's understanding of *this* animation.
    private static let houseAnimationSwell: Double = 0.18
    
    /// How far the struck stone tumbles as it is flung off, in degrees. Fixed rather than tunable,
    /// for the same reason as `houseAnimationSwell`.
    private static let houseAnimationSpin: Double = 540
    
    /// The delivered stone's curl, in degrees per 1.0 of normalized sheet travel — a *rate*, not a
    /// fixed sweep, so a short flick spins proportionally less instead of whipping round at the
    /// same total angle as a full-power tap. At full power (~0.80 of the sheet) this is ~2 turns.
    private static let deliverySpinPerUnitTravel: Double = 100
    
    // MARK: - Panel-bound state
    //
    // Fully settable: `ControlPanelView` binds through `$model.…` via @Bindable, and
    // `ContentView.init` assigns the two style properties below.
    public var deliveryAnimationStyle: DeliveryAnimationStyle = .linear
    
    public var houseAnimationStyle: HouseAnimationStyle = .linear
    
    /// How a delivery is triggered. Tap is the default: it always delivers at full power, so two
    /// animation styles are only ever compared over the same travel distance — a flick's distance
    /// varies with release, which is fine for play but would confound that comparison.
    public var deliveryMethod: LaunchMethod = .tap
    
    /// Multiplies release speed to get travel distance: `travel = flickPower * speed`, the same
    /// formula and meaning at every value on the slider. Measured release speeds from a
    /// mouse-driven drag in Simulator land around 0.3-1.2, well short of what a real finger
    /// flick produces, which is why the slider's range runs high enough that even a speed of
    /// ~0.3 reaches the top of the house at max power.
    public var flickPower: Double = 1.0
    
    // MARK: - Read-only state
    
    public private(set) var deliveredStone = Stone(position: CurlingSheet.hackRestPosition, color: .red)
    
    public private(set) var isDeliveringStone = false
    
    /// True while the player has the stone under their finger in Flick mode — from touch-down,
    /// not just once it moves, since the gesture uses `minimumDistance: 0`.
    public private(set) var isDraggingStone = false
    
    public private(set) var statusMessage = "Ready"
    
    public private(set) var sheet: CurlingSheet
    
    // MARK: - Private storage
    
    // One copy of each section's tunables per style, so switching styles in either picker never
    // discards tuning already done on another style.
    private var deliveryTuningByStyle = Dictionary(
        uniqueKeysWithValues: DeliveryAnimationStyle.allCases.map { ($0, DeliveryTuning()) }
    )
    
    private var houseTuningByStyle = Dictionary(
        uniqueKeysWithValues: HouseAnimationStyle.allCases.map { ($0, HouseTuning()) }
    )
    
    private var dragAnchorY: CGFloat = CurlingSheet.hackRestY
    
    private var deliveryTask: Task<Void, Never>?
    
    public init(sheet: CurlingSheet = CurlingSheet()) {
        self.sheet = sheet
    }
    
    /// The tunables belonging to whichever delivery style is selected. Every slider in the
    /// Delivery section binds through here, so each style edits only its own numbers.
    public var delivery: DeliveryTuning {
        get { deliveryTuningByStyle[deliveryAnimationStyle] ?? DeliveryTuning() }
        set { deliveryTuningByStyle[deliveryAnimationStyle] = newValue }
    }
    
    /// The tunables belonging to whichever house style is selected. Every slider in the House
    /// Animation section binds through here, so each style edits only its own numbers.
    public var house: HouseTuning {
        get { houseTuningByStyle[houseAnimationStyle] ?? HouseTuning() }
        set { houseTuningByStyle[houseAnimationStyle] = newValue }
    }
    
    /// Called from every `onChanged`. `offset` is cumulative translation over sheet height,
    /// so it is negative when the finger moves up. A no-op in Tap mode — the drag it belongs to is
    /// disabled at the view (`DeliveredStoneView`), but the view model enforces its own invariant
    /// rather than trusting the view to gate it.
    public func dragStone(byNormalizedOffset offset: CGFloat) {
        guard deliveryMethod == .flick, !isDeliveringStone else { return }
        if !isDraggingStone {
            isDraggingStone = true
            dragAnchorY = deliveredStone.position.y        // anchor captured once, on the first change
            statusMessage = "Release to throw"
        }
        deliveredStone.position.y = min(max(dragAnchorY + offset, CurlingSheet.dragBand.lowerBound),
                                        CurlingSheet.dragBand.upperBound)
    }
    
    /// `velocity` is vertical gesture velocity over sheet height; negative is upward. A no-op in
    /// Tap mode — see `dragStone(byNormalizedOffset:)`.
    public func releaseStone(normalizedVelocityY velocity: CGFloat) {
        guard deliveryMethod == .flick, isDraggingStone else { return }
        isDraggingStone = false
        
        let speed = -velocity
        guard speed >= Self.minimumFlickVelocity else {
            statusMessage = "Flick up to deliver"
            withAnimation(.snappy(duration: 0.3)) { resetDeliveredStonePosition() }
            return
        }
        // Travel is measured from where the stone was released, not from the hack.
        deliverStone(stoppingAt: max(deliveredStone.position.y - CGFloat(flickPower) * speed, CurlingSheet.houseTopY))
    }
    
    /// Full-power delivery: used directly by Tap mode, and by the accessibility action where
    /// there is no gesture velocity to read.
    public func deliverStone() {
        deliverStone(stoppingAt: CurlingSheet.houseTopY)
    }
    
    private func deliverStone(stoppingAt stopY: CGFloat) {
        guard !isDeliveringStone else {
            statusMessage = "Already animating"
            return
        }
        isDeliveringStone = true
        
        guard let targetIndex = sheet.firstStoneInPath(stoppingAt: stopY) else {
            // A stone sent through an already-empty house is the sheet's cue to set itself out
            // again — captured now, before the throw plays, since `resetHouse()` below will
            // replace `sheet` out from under `sheet.isEmpty`.
            let clearsSheet = stopY <= CurlingSheet.hogLineY && sheet.isEmpty
            statusMessage = deliveryOutcomeDescription(stoppingAt: stopY)
            let curl = Angle.degrees(Self.deliverySpinPerUnitTravel * abs(deliveredStone.position.y - stopY))
            withAnimation(deliveryAnimator.animation) {
                deliveredStone.position.y = stopY
                deliveredStone.rotation += curl
            }
            deliveryTask = Task {
                guard await pause(deliveryAnimator.playDuration) else { return }
                finishDeliverySequence()
                guard clearsSheet else { return }
                // Let the delivered stone settle into the hack first, so the reset reads as a second,
                // distinct beat rather than overlapping the return animation.
                guard await pause(0.45) else { return }
                resetHouse()
            }
            return
        }
        
        // A struck stone stops the thrown stone at the target's position, and hands off to
        // `applyHouseAnimation(to:)` once the faked contact delay elapses.
        statusMessage = "Delivery"
        let hitCurl = Angle.degrees(Self.deliverySpinPerUnitTravel
                                    * abs(deliveredStone.position.y - sheet.stones[targetIndex].position.y))
        withAnimation(deliveryAnimator.animation) {
            deliveredStone.position.y = sheet.stones[targetIndex].position.y
            deliveredStone.rotation += hitCurl
        }
        deliveryTask = Task {
            guard await pause(deliveryAnimator.contactDelay) else { return }
            await applyHouseAnimation(to: targetIndex)
        }
    }
    
    /// Curling terminology for what this does: sweep the sheet clean and set out a fresh house.
    /// Also the app's manual escape hatch — the auto-reset in `deliverStone(stoppingAt:)` normally beats
    /// the player to it, but this is what runs when they want a new house immediately.
    @MainActor
    public func resetHouse() {
        cancelDelivery()
        isDraggingStone = false
        withAnimation(.easeInOut(duration: 0.4)) {
            sheet = CurlingSheet()
        }
        resetDeliveredStonePosition()
        statusMessage = "New house"
    }
    
    /// Shown whenever the house is empty and idle — after a miss that swept it clean, or after the
    /// hit that struck the last standing stone — so the player always knows delivering once more
    /// now sets out a fresh house. Worded per `deliveryMethod`, since "flick through" means
    /// nothing in Tap mode.
    private var houseEmptyPrompt: String { deliveryMethod.houseEmptyPrompt }
    
    private func deliveryOutcomeDescription(stoppingAt stopY: CGFloat) -> String {
        if stopY > CurlingSheet.hogLineY { return "Hogged" }
        if !sheet.isEmpty { return "Short" }
        return houseEmptyPrompt
    }
    
    /// Sleeps for `seconds`, returning false if the delivery was cancelled while waiting.
    /// Every animation phase goes through here, so Reset can interrupt a sequence mid-flight.
    private func pause(_ seconds: Double) async -> Bool {
        do {
            try await Task.sleep(for: .seconds(max(seconds, 0.1)))
            return true
        } catch {
            return false
        }
    }
    
    /// Stops any in-flight delivery and clears the gate on new ones. The caller owns the
    /// cleanup, which is why an interrupted sequence must not reach `finishDeliverySequence()`.
    private func cancelDelivery() {
        deliveryTask?.cancel()
        deliveryTask = nil
        isDeliveringStone = false
    }
    
    /// What the struck stone does: ejected in a random direction and swollen on the tuned
    /// animation, then faded out on a fixed curve. `pause(_:)` returns false if a Reset cancelled
    /// the delivery mid-flight; both phases bail out through that rather than push on with a
    /// `sheet.stones` array that may have just been replaced with a differently-sized random
    /// house.
    @MainActor
    private func applyHouseAnimation(to index: Int) async {
        guard sheet.stones.indices.contains(index) else {
            finishDeliverySequence()
            return
        }
        
        statusMessage = "House animation: \(houseAnimationStyle.title)"
        
        // Beat one — the tuned animation. The struck stone is ejected in a random direction, far
        // enough to fly off the sheet, swells, and tumbles. The only beat the panel controls, and
        // the only one worth watching — a big, random path is what makes linear/spring/ease/bouncy
        // actually look different from one another, which a small fixed nudge never did.
        //
        // No clamp to `houseTopY` here: that clamp existed to keep the old straight-back knock-back
        // inside the playable area. This stone is supposed to leave — `CurlingSheetView`'s own
        // `.clipShape(Rectangle())` already hides it once `position.x`/`position.y` cross the
        // sheet's `[0, 1]` bounds.
        let ejectAngle = CGFloat.random(in: 0..<(2 * .pi))
        // The eject direction is already random, so a fixed tumble direction would look wrong
        // against it.
        let spinDirection: Double = Bool.random() ? 1 : -1
        withAnimation(houseAnimator.animation) {
            sheet.stones[index].position.x += cos(ejectAngle) * Self.houseExitDistance
            sheet.stones[index].position.y += sin(ejectAngle) * Self.houseExitDistance * CurlingSheet.aspectRatio
            sheet.stones[index].scale = 1 + Self.houseAnimationSwell
            sheet.stones[index].rotation += .degrees(Self.houseAnimationSpin * spinDirection)
        }
        guard await pause(houseAnimator.playDuration) else { return }
        
        // Beat two — cleanup, deliberately not tunable, on its own fixed curve. Opacity and
        // position want different timing: a low-damping spring rings for over a second, and a
        // stone that faded on the same curve would be invisible before the room saw the wobble.
        withAnimation(.easeOut(duration: Self.fadeOutDuration)) {
            sheet.stones[index].opacity = 0
        }
        guard await pause(Self.fadeOutDuration) else { return }
        // `isVisible` is a hard on/off flag, not animatable — flipped outside `withAnimation` as
        // cleanup.
        sheet.stones[index].isVisible = false
        
        finishDeliverySequence()
    }
    
    /// The one place a delivery ends, whether it struck a stone or fell short. Also the one place
    /// that notices the house just became empty — including when the delivery that emptied it was
    /// a hit, not a miss — and updates the status to say so, rather than leaving whatever message
    /// the hit set (e.g. "House animation: X") stale on screen.
    @MainActor
    private func finishDeliverySequence() {
        withAnimation(.easeInOut(duration: 0.35)) {
            resetDeliveredStonePosition()
        }
        isDeliveringStone = false
        if sheet.isEmpty {
            statusMessage = houseEmptyPrompt
        }
    }
    
    /// Resets `position` and `rotation` of the delivered stone to start from scratch for the next delivery and look consistent on every delivery
    private func resetDeliveredStonePosition() {
        deliveredStone.position = CurlingSheet.hackRestPosition
        deliveredStone.rotation = Angle.zero
    }
    
    /// The delivery animation at the currently selected style and tuning. A plain value built
    /// fresh from published state, not stored — see `DeliveryAnimator`.
    private var deliveryAnimator: DeliveryAnimator {
        DeliveryAnimator(style: deliveryAnimationStyle, tuning: delivery)
    }
    
    /// The house animation at the currently selected style and tuning — see `HouseAnimator`.
    private var houseAnimator: HouseAnimator {
        HouseAnimator(style: houseAnimationStyle, tuning: house)
    }
}
