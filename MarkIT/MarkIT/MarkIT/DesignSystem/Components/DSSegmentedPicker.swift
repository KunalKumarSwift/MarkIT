import SwiftUI

/// A pill-shaped segmented picker that matches the HTML reference design.
///
/// Usage:
/// ```swift
/// DSSegmentedPicker(
///     options: GoalPeriod.allCases,
///     selection: $selectedPeriod
/// ) { option in
///     Text(option.label)
/// }
/// ```
struct DSSegmentedPicker<Option: Hashable & Identifiable, Label: View>: View {
    let options: [Option]
    @Binding var selection: Option
    @ViewBuilder var label: (Option) -> Label

    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                Button {
                    withAnimation(DSAnimation.snappy) {
                        selection = option
                    }
                } label: {
                    label(option)
                        .font(DSFont.subheadline)
                        .foregroundStyle(selection == option ? DSColors.accent : DSColors.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DSSpacing.sm)
                        .background {
                            if selection == option {
                                Capsule()
                                    .fill(DSColors.surface)
                                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                                    .matchedGeometryEffect(id: "segment", in: animation)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DSSpacing.xs)
        .background(DSColors.secondaryBackground)
        .clipShape(Capsule())
    }
}
