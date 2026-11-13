import SwiftUI

struct ZoneStatusPopover: View {
    let info: ZoneStatusInfo
    var onClose: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ZoneStatus.categoryName(info.category))
                .font(.headline)
                .accessibilityIdentifier("zoneStatus.category")

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                statusRow("Density:", ZoneStatus.densityName(info.density), id: "density")
                statusRow("Value:", ZoneStatus.valueName(info.landValue), id: "value")
                statusRow("Crime:", ZoneStatus.crimeName(info.crime), id: "crime")
                statusRow("Pollution:", ZoneStatus.pollutionName(info.pollution), id: "pollution")
                statusRow("Growth:", ZoneStatus.growthName(info.growth), id: "growth")
            }
            .font(.system(.caption, design: .default))

            Button("Close", action: onClose)
                .accessibilityIdentifier("zoneStatus.close")
        }
        .padding(8)
        .frame(width: 160)
    }

    private func statusRow(_ label: String, _ value: String, id: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).accessibilityIdentifier("zoneStatus.\(id)")
        }
    }
}
