import SwiftUI

/// Figma: Metric Tile. One summary number on the Unit tab. Two per row on iPhone.
public struct MetricTile: View {
    let value: String
    let label: String

    public init(value: String, label: String) {
        self.value = value
        self.label = label
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: VigilLayout.Space.xs) {
            Text(value)
                .font(.title.weight(.semibold))
                .foregroundStyle(VigilToken.Tile.value)
            Text(label)
                .font(.footnote)
                .foregroundStyle(VigilToken.Tile.label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(VigilLayout.Space.l)
        .background(VigilToken.Tile.background, in: RoundedRectangle(cornerRadius: VigilLayout.Radius.tile))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    MetricTile(value: "230", label: "Hours monitored").padding()
}
