import SwiftUI

/// Figma: Vital Row. One live reading from the watch.
/// `meta` must give the direction of change and how fresh the reading is, for example "Down from 92 · 10 sec ago".
/// Only show signals the watch really measures.
public struct VitalRow: View {
    let label: String
    let value: String
    let unit: String
    let meta: String

    public init(label: String, value: String, unit: String = "", meta: String) {
        self.label = label
        self.value = value
        self.unit = unit
        self.meta = meta
    }

    public var body: some View {
        HStack(spacing: VigilLayout.Space.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.body)
                    .foregroundStyle(VigilToken.Vital.label)
                Text(meta)
                    .font(.footnote)
                    .foregroundStyle(VigilToken.Vital.meta)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .firstTextBaseline, spacing: VigilLayout.Space.xs) {
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(VigilToken.Vital.value)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.subheadline)
                        .foregroundStyle(VigilToken.Vital.unit)
                }
            }
        }
        .padding(.horizontal, VigilLayout.Space.l)
        .padding(.vertical, 10)
        .background(VigilToken.Row.background)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VitalRow(label: "Heart rate", value: "78", unit: "bpm", meta: "Down from 92 · 10 sec ago")
}
