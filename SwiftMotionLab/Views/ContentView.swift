import SwiftUI

/// The app's root view and single source of truth: it owns the `MotionLabViewModel` and chooses
/// between a side-by-side regular layout and a compact layout with the tuning panel in a sheet.
public struct ContentView: View {
    @State private var model: MotionLabViewModel
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var isPanelPresented = true
    
    @State private var panelDetent: PresentationDetent = PanelDetent.collapsed
    
    private let iceTone: MotionLabRinkView.IceTone

    /// Lets previews pin an initial delivery animation style, house animation style, and ice tone
    /// without giving up this view's own size-class-adaptive layout — the compact sheet's
    /// collapsed-by-default detent is what actually keeps the rink visible in a phone-sized
    /// preview canvas.
    public init(deliveryAnimationStyle: DeliveryAnimationStyle? = nil, houseAnimationStyle: HouseAnimationStyle? = nil, iceTone: MotionLabRinkView.IceTone = .dark70) {
        let model = MotionLabViewModel()
        if let deliveryAnimationStyle { model.deliveryAnimationStyle = deliveryAnimationStyle }
        if let houseAnimationStyle { model.houseAnimationStyle = houseAnimationStyle }
        _model = State(initialValue: model)
        self.iceTone = iceTone
    }

    private enum PanelDetent {
        fileprivate static let collapsedHeight: CGFloat = 65
        fileprivate static let collapsed = PresentationDetent.height(collapsedHeight)
        fileprivate static let partial = PresentationDetent.fraction(0.45)
        fileprivate static let all: Set<PresentationDetent> = [collapsed, partial, .large]
        fileprivate static let expandedHeaderTopPadding: CGFloat = 25
    }

    public var body: some View {
        if horizontalSizeClass == .compact {
            compactLayout
        } else {
            regularLayout
        }
    }

    private var regularLayout: some View {
        HStack(spacing: 20) {
            canvasPane(showsNeighbouringSheets: true)
            panelPane
                .frame(width: 360)
        }
        .padding()
    }

    private var compactLayout: some View {
        canvasPane(showsNeighbouringSheets: false)
            .padding()
            .safeAreaInset(edge: .bottom) {
                // Reserves exactly the collapsed sheet's own height, so the rink fills the rest
                // of the available space instead of leaving a gap sized by guesswork.
                Color.clear.frame(height: PanelDetent.collapsedHeight)
            }
            .sheet(isPresented: $isPanelPresented) {
                panelSheet
                    .presentationDetents(PanelDetent.all, selection: $panelDetent)
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled()
                    .presentationBackgroundInteraction(.enabled(upThrough: PanelDetent.partial))
                    .presentationCompactAdaptation(.sheet)
            }
    }

    private func canvasPane(showsNeighbouringSheets: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Swift\(Text("Motion").italic().foregroundStyle(.blue)) Lab")
                .font(.largeTitle.weight(.bold))
            Text("Send the stone into the house, then compare how different animations carry it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            MotionLabRinkView(model: model, showsNeighbouringSheets: showsNeighbouringSheets, iceTone: iceTone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var panelPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tuning Panel")
                .font(.title3.weight(.semibold))
            Text("Designed for short demos and side-by-side preview exploration.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ControlPanelView(model: model)
        }
    }

    private var isPanelCollapsed: Bool {
        panelDetent == PanelDetent.collapsed
    }

    private var panelSheet: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation {
                    panelDetent = isPanelCollapsed ? PanelDetent.partial : PanelDetent.collapsed
                }
            } label: {
                HStack(spacing: 12) {
                    Text("Tuning Panel")
                        .font(.title3.weight(.regular))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isPanelCollapsed ? 0 : 180))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxHeight: isPanelCollapsed ? .infinity : nil)

            if !isPanelCollapsed {
                Text("Designed for short demos and side-by-side preview exploration.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ControlPanelView(model: model)
            }
        }
        .padding(.horizontal)
        .padding(.top, isPanelCollapsed ? 0 : PanelDetent.expandedHeaderTopPadding)
    }
}

#Preview("Starter · Collapsed") {
    ContentView()
}
