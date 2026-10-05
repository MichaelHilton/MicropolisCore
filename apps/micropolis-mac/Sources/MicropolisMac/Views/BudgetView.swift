import SwiftUI

struct BudgetView: View {
    @Environment(GameModel.self) var model
    @Environment(\.dismiss) var dismiss

    @State private var taxRate: Double = 0
    @State private var roadPercent: Double = 50
    @State private var policePercent: Double = 50
    @State private var firePercent: Double = 50

    var body: some View {
        VStack(spacing: 16) {
            Text("Budget")
                .font(.headline)

            HStack {
                Text("Funds: $\(model.funds)")
                    .font(.system(.body, design: .monospaced))
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                SliderRow(
                    label: "Tax Rate",
                    value: $taxRate,
                    range: 0...20,
                    format: "%.0f%%"
                )

                SliderRow(
                    label: "Road Funding",
                    value: $roadPercent,
                    range: 0...100,
                    format: "%.0f%%"
                )

                SliderRow(
                    label: "Police Funding",
                    value: $policePercent,
                    range: 0...100,
                    format: "%.0f%%"
                )

                SliderRow(
                    label: "Fire Funding",
                    value: $firePercent,
                    range: 0...100,
                    format: "%.0f%%"
                )
            }

            Divider()

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("OK") {
                    applyBudget()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(minWidth: 300)
        .onAppear {
            taxRate = Double(model.engine.tax)
            roadPercent = Double(model.engine.roadPercent) * 100
            policePercent = Double(model.engine.policePercent) * 100
            firePercent = Double(model.engine.firePercent) * 100
        }
    }

    private func applyBudget() {
        model.engine.setTax(Int(taxRate))
        model.engine.setRoadPercent(Float(roadPercent) / 100)
        model.engine.setPolicePercent(Float(policePercent) / 100)
        model.engine.setFirePercent(Float(firePercent) / 100)
    }
}

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
            Slider(value: $value, in: range)
            Text(String(format: format, value))
                .frame(width: 50, alignment: .trailing)
                .font(.system(.body, design: .monospaced))
        }
    }
}
