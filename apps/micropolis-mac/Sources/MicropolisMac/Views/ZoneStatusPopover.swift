import SwiftUI

struct ZoneStatusPopover: View {
    let info: ZoneStatusInfo
    var onClose: () -> Void = {}
    var theme: ChromeTheme? = nil

    var body: some View {
        if let theme {
            content.font(theme.font(12)).foregroundStyle(theme.ink).tint(theme.accentFill)
                .background(theme.window)
                .environment(\.colorScheme, theme.windowScheme)
        } else {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ZoneStatus.categoryName(info.category))
                .font(theme?.font(14) ?? .headline)
                .foregroundStyle(theme?.heading ?? .primary)
                .accessibilityIdentifier("zoneStatus.category")

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                statusRow("Density:", ZoneStatus.densityName(info.density), id: "density")
                statusRow("Value:", ZoneStatus.valueName(info.landValue), id: "value")
                statusRow("Crime:", ZoneStatus.crimeName(info.crime), id: "crime")
                statusRow("Pollution:", ZoneStatus.pollutionName(info.pollution), id: "pollution")
                statusRow("Growth:", ZoneStatus.growthName(info.growth), id: "growth")
            }
            .font(theme?.font(11) ?? .system(.caption, design: .default))

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
