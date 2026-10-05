import SwiftUI

struct HUDView: View {
    @Environment(GameModel.self) var model

    let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    var body: some View {
        VStack(spacing: 0) {
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

                if let message = model.toolMessage {
                    Text(message)
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.red)
                }

                Spacer()

                // Demand gauge
                HStack(spacing: 4) {
                    DemandBar(value: model.demandResidential, color: .green, label: "R")
                    DemandBar(value: model.demandCommercial, color: .blue, label: "C")
                    DemandBar(value: model.demandIndustrial, color: .yellow, label: "I")
                }
                .frame(width: 60)

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
    }

    var monthName: String {
        let index = (model.month - 1) % 12
        return monthNames[max(0, min(index, 11))]
    }
}

struct DemandBar: View {
    let value: Float
    let color: Color
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: CGFloat(max(4, (value + 1) * 12)))
            Text(label)
                .font(.system(.caption2, design: .default))
        }
        .frame(height: 30)
    }
}
