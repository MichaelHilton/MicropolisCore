import SwiftUI

struct ZoneStatusPopover: View {
    let info: ZoneStatusInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(ZoneStatus.categoryName(info.category))
                .font(.headline)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack { Text("Density:"); Spacer(); Text(ZoneStatus.densityName(info.density)) }
                HStack { Text("Value:"); Spacer(); Text(ZoneStatus.valueName(info.landValue)) }
                HStack { Text("Crime:"); Spacer(); Text(ZoneStatus.levelName(info.crime)) }
                HStack { Text("Pollution:"); Spacer(); Text(ZoneStatus.levelName(info.pollution)) }
                HStack { Text("Growth:"); Spacer(); Text(ZoneStatus.growthName(info.growth)) }
            }
            .font(.system(.caption, design: .default))
        }
        .padding(8)
        .frame(width: 160)
    }
}
