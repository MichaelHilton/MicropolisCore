import SwiftUI
import MicropolisKit

/// The figures on the DOS budget screen, worked out from what the engine
/// reports and the levels the player has set.
struct BudgetSheet: Equatable {
    var figures: BudgetFigures
    var funds: Int
    var taxRate: Int
    /// Funding levels in percent, 0...100.
    var roadLevel: Int
    var policeLevel: Int
    var fireLevel: Int

    var roadAllocated: Int { figures.roadRequested * roadLevel / 100 }
    var policeAllocated: Int { figures.policeRequested * policeLevel / 100 }
    var fireAllocated: Int { figures.fireRequested * fireLevel / 100 }
    var cashFlow: Int { figures.taxesCollected - roadAllocated - policeAllocated - fireAllocated }
    var currentFunds: Int { funds + cashFlow }

    static let taxRange = 0...20
    static let levelRange = 0...100

    /// Dollars as the budget window prints them: "$1,234" or "-$1,234".
    static func money(_ value: Int) -> String {
        (value < 0 ? "-$" : "$") + abs(value).formatted()
    }
}

struct BudgetView: View {
    @Environment(GameModel.self) var model
    @Environment(\.dismiss) var dismiss

    @State private var sheet: BudgetSheet?

    var body: some View {
        VStack(spacing: 10) {
            if let sheet = Binding($sheet) {
                content(sheet)
            }
        }
        .font(DOS.font())
        .foregroundColor(DOS.blue)
        .padding(16)
        .frame(width: 520)
        .background(DOS.white)
        .overlay(Rectangle().stroke(DOS.lightBlue, lineWidth: 4))
        .onAppear { sheet = model.makeBudgetSheet() }
    }

    @ViewBuilder
    private func content(_ sheet: Binding<BudgetSheet>) -> some View {
        let s = sheet.wrappedValue
        Text("\(String(model.year)) Fiscal Budget").font(DOS.font(16))
        Rectangle().fill(DOS.blue).frame(height: 2)
        Rectangle().fill(DOS.blue).frame(height: 1)

        HStack(spacing: 16) {
            Text("Tax Rate")
            Stepper2(value: sheet.taxRate, range: BudgetSheet.taxRange, label: "\(s.taxRate)%")
        }
        HStack(spacing: 16) {
            Text("Taxes collected")
            Text(BudgetSheet.money(s.figures.taxesCollected))
        }

        Grid(alignment: .trailing, horizontalSpacing: 16, verticalSpacing: 10) {
            GridRow {
                Text("")
                Text("Amount\nRequested").multilineTextAlignment(.center).fixedSize()
                Text("Amount\nAllocated").multilineTextAlignment(.center).fixedSize()
                Text("Funding\nLevel").multilineTextAlignment(.center).fixedSize()
            }
            Divider().gridCellUnsizedAxes(.horizontal).overlay(DOS.white)
            departmentRow("Trans", s.figures.roadRequested, s.roadAllocated, sheet.roadLevel)
            departmentRow("Police", s.figures.policeRequested, s.policeAllocated, sheet.policeLevel)
            departmentRow("Fire", s.figures.fireRequested, s.fireAllocated, sheet.fireLevel)
        }
        .foregroundColor(DOS.white)
        .padding(10)
        .background(DOS.lightBlue)
        .overlay(Rectangle().stroke(Color(red: 0.67, green: 1, blue: 1), lineWidth: 3))

        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 2) {
            GridRow { Text("Cash Flow"); Text(BudgetSheet.money(s.cashFlow)) }
            GridRow { Text("Previous Fund"); Text(BudgetSheet.money(s.funds)) }
            Divider().gridCellColumns(2).overlay(DOS.blue)
            GridRow { Text("Current Funds"); Text(BudgetSheet.money(s.currentFunds)) }
        }

        Button(action: apply) {
            Text("Go with these figures")
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(red: 0.67, green: 1, blue: 1))
                .overlay(Rectangle().stroke(DOS.blue, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.defaultAction)
    }

    private func departmentRow(_ name: String, _ requested: Int, _ allocated: Int, _ level: Binding<Int>) -> some View {
        GridRow {
            Text(name)
            Text(BudgetSheet.money(requested))
            Text(BudgetSheet.money(allocated))
            Stepper2(value: level, range: BudgetSheet.levelRange, label: "\(level.wrappedValue)%")
        }
    }

    private func apply() {
        guard let sheet else { return }
        model.applyBudget(sheet)
        dismiss()
    }
}

/// The DOS up/down arrow pair around a value. Option-click moves by 10.
struct Stepper2: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: String

    var body: some View {
        HStack(spacing: 0) {
            arrow("▲", +1)
            Text(label)
                .frame(minWidth: 52, alignment: .trailing)
                .foregroundColor(DOS.white)
                .background(DOS.blue)
            arrow("▼", -1)
        }
    }

    private func arrow(_ glyph: String, _ direction: Int) -> some View {
        Button {
            let step = NSEvent.modifierFlags.contains(.option) ? 10 : 1
            value = min(range.upperBound, max(range.lowerBound, value + direction * step))
        } label: {
            Text(glyph)
                .font(DOS.font(11))
                .foregroundColor(DOS.white)
                .frame(width: 16, height: 20)
                .background(Color(red: 0.67, green: 1, blue: 1).opacity(0.6))
        }
        .buttonStyle(.plain)
    }
}
