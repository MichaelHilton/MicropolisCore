import SwiftUI

struct HUDView: View {
    @Environment(GameModel.self) var model

    let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    var body: some View {
        HStack(spacing: 16) {
            Text("\(monthName) \(model.year)")
                .font(.system(.body, design: .monospaced))

            HStack {
                Text("$\(model.funds)")
                    .font(.system(.body, design: .monospaced))
            }

            HStack {
                Text("\(model.population)")
                    .font(.system(.body, design: .monospaced))
            }

            Spacer()

            Picker("Speed", selection: Binding(
                get: { model.speed },
                set: { model.setSpeed($0) }
            )) {
                Text("Pause").tag(0)
                Text("Slow").tag(1)
                Text("Medium").tag(2)
                Text("Fast").tag(3)
            }
            .pickerStyle(.segmented)
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .border(Color(nsColor: .separatorColor), width: 1)
    }

    var monthName: String {
        let index = (model.month - 1) % 12
        return monthNames[max(0, min(index, 11))]
    }
}
