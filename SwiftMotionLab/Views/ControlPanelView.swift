import SwiftUI

// The tuning panel: Delivery, House Animation, and Actions sections over a MotionLabViewModel.
// `ControlPanelView`, below the two private helper types it's built from, is generated from
// `DeliveryAnimationStyle` / `HouseAnimationStyle` and their `parameters` catalogs, defined in
// `DeliveryAnimator.swift` / `HouseAnimator.swift`.

private extension Text {
    /// The one style for every explanatory note in this panel — animation descriptions, the Flick
    /// Power hint, and anything added later. Kept in one place so they always match, and never on
    /// their own row: apply it to a `Text` stacked directly beneath the control it explains.
    func panelNote() -> some View {
        font(.body).foregroundStyle(.secondary)
    }
}

/// One tunable: a labelled read-out and the slider that drives it. Every parameter in the panel
/// is one of these, so adding a new one is a single line.
private struct TuningSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading) {
            LabeledContent(title) { Text(value, format: .number.precision(.fractionLength(2))) }
            if let caption {
                Text(caption).panelNote()
            }
            Slider(value: $value, in: range)
        }
    }
}

public struct ControlPanelView: View {
    @Bindable public var model: MotionLabViewModel

    public init(model: MotionLabViewModel) {
        self.model = model
    }

    public var body: some View {
        Form {
            Section("Delivery") {
                VStack(alignment: .leading) {
                    Picker("Delivery Animation", selection: $model.deliveryAnimationStyle) {
                        ForEach(DeliveryAnimationStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    Text(model.deliveryAnimationStyle.description).panelNote()
                }

                deliveryControls
            }

            Section("House Animation") {
                // Driven by `HouseAnimationStyle.allCases`, so the picker lists whatever styles
                // exist. The enum is the contract between the model and the UI.
                VStack(alignment: .leading) {
                    Picker("House Animation", selection: $model.houseAnimationStyle) {
                        ForEach(HouseAnimationStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    Text(model.houseAnimationStyle.description).panelNote()
                }

                houseControls
            }

            Section("Actions") {
                VStack(alignment: .leading) {
                    Picker("Delivery Method", selection: $model.deliveryMethod) {
                        ForEach(MotionLabViewModel.LaunchMethod.allCases) { method in
                            Text(method.title).tag(method)
                        }
                    }
                    Text(model.deliveryMethod.description).panelNote()
                }

                if model.deliveryMethod == .flick {
                    TuningSlider(
                        title: "Flick Power",
                        value: $model.flickPower,
                        range: 0.10...3.0,
                        caption: "Increase when using a mouse."
                    )
                }

                Button("Reset Sheet", role: .none) { model.resetHouse() }
            }
        }
        .formStyle(.grouped)
    }

    // Generated from `model.deliveryAnimationStyle.parameters` — see `DeliveryAnimationStyle` in
    // DeliveryAnimator.swift.
    private var deliveryControls: some View {
        ForEach(model.deliveryAnimationStyle.parameters) { parameter in
            TuningSlider(
                title: parameter.title,
                value: $model.delivery[dynamicMember: parameter.keyPath],
                range: parameter.range,
                caption: parameter.caption
            )
        }
    }

    // Generated from `model.houseAnimationStyle.parameters` — see `HouseAnimationStyle` in
    // HouseAnimator.swift.
    private var houseControls: some View {
        ForEach(model.houseAnimationStyle.parameters) { parameter in
            TuningSlider(
                title: parameter.title,
                value: $model.house[dynamicMember: parameter.keyPath],
                range: parameter.range,
                caption: parameter.caption
            )
        }
    }
}

#Preview("Panel · delivery styles", arguments: DeliveryAnimationStyle.allCases) { style in
    ControlPanelView(model: PreviewData.model(deliveryAnimationStyle: style))
}

#Preview("Panel · house styles", arguments: HouseAnimationStyle.allCases) { style in
    ControlPanelView(model: PreviewData.model(houseAnimationStyle: style))
}
