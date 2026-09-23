import SwiftUI

/// Named delivery/house pairings used by the app's canonical previews, so each preview reads
/// as a scenario rather than a bare pair of enum cases.
public enum PreviewData {
    public struct Scenario {
        private let _deliveryAnimationStyle: DeliveryAnimationStyle
        private let _houseAnimationStyle: HouseAnimationStyle
        private let _iceTone: MotionLabRinkView.IceTone

        public init(deliveryAnimationStyle: DeliveryAnimationStyle, houseAnimationStyle: HouseAnimationStyle, iceTone: MotionLabRinkView.IceTone = .dark70) {
            _deliveryAnimationStyle = deliveryAnimationStyle
            _houseAnimationStyle = houseAnimationStyle
            _iceTone = iceTone
        }

        public var deliveryAnimationStyle: DeliveryAnimationStyle { _deliveryAnimationStyle }
        public var houseAnimationStyle: HouseAnimationStyle { _houseAnimationStyle }
        public var iceTone: MotionLabRinkView.IceTone { _iceTone }
    }

    /// The demo's starting point: both phases mechanically boring on purpose.
    public static let linearBaseline = Scenario(deliveryAnimationStyle: .linear, houseAnimationStyle: .linear)

    /// A `MotionLabViewModel` pinned to the given styles, for previews that only need the panel,
    /// not the whole rink — see `ContentView.init(_:)` below for the rink's equivalent.
    public static func model(deliveryAnimationStyle: DeliveryAnimationStyle = .linear, houseAnimationStyle: HouseAnimationStyle = .linear) -> MotionLabViewModel {
        let model = MotionLabViewModel()
        model.deliveryAnimationStyle = deliveryAnimationStyle
        model.houseAnimationStyle = houseAnimationStyle
        return model
    }
}

extension ContentView {
    public init(_ scenario: PreviewData.Scenario) {
        self.init(
            deliveryAnimationStyle: scenario.deliveryAnimationStyle,
            houseAnimationStyle: scenario.houseAnimationStyle,
            iceTone: scenario.iceTone
        )
    }
}
