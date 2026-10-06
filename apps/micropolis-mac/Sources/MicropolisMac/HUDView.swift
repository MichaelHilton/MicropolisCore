import SwiftUI

/// The top of the DOS screen: a menu strip, then a grey title bar with the
/// city name and date, then the Funds line.
struct HUDView: View {
    @Environment(GameModel.self) var model

    let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    var body: some View {
        VStack(spacing: 0) {
            DOSMenuStrip()

            ZStack {
                Text(model.cityName)
                    .foregroundColor(DOS.black)
                HStack {
                    Rectangle()
                        .fill(DOS.white)
                        .frame(width: 10, height: 10)
                        .overlay(Rectangle().stroke(DOS.black, lineWidth: 1))
                    Spacer()
                    Text("\(monthName) \(String(model.year))")
                        .foregroundColor(DOS.black)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(DOS.lightGray)

            HStack(spacing: 16) {
                Text("Funds: $\(model.funds.formatted())")
                Spacer()
                if let message = model.currentMessage {
                    Text(message)
                        .foregroundColor(DOS.yellow)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .foregroundColor(DOS.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(DOS.darkGray)
        }
        .font(DOS.font())
    }

    var monthName: String {
        let index = (model.month - 1) % 12
        return monthNames[max(0, min(index, 11))]
    }
}

/// The SYSTEM / OPTIONS / DISASTERS / WINDOWS strip. It mirrors the macOS
/// menu bar so the window looks like the DOS game without losing Mac menus.
struct DOSMenuStrip: View {
    @Environment(GameModel.self) var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var model = model

        HStack(spacing: 0) {
            stripMenu("SYSTEM") {
                Button("New City") { model.newCity(seed: Int.random(in: 1...9999)) }
                Button("Open…") { model.showOpenPanel() }
                Menu("Open Scenario") {
                    ForEach(Assets.allCities, id: \.self) { url in
                        Button(url.deletingPathExtension().lastPathComponent) {
                            model.loadCity(from: url)
                        }
                    }
                }
                Divider()
                Button("Save") { model.save() }
                Button("Save As…") { model.showSavePanel() }
            }

            stripMenu("OPTIONS") {
                Picker("Speed", selection: Binding(
                    get: { model.speed },
                    set: { model.setSpeed($0) }
                )) {
                    Text("Pause").tag(0)
                    Text("Slow").tag(1)
                    Text("Medium").tag(2)
                    Text("Fast").tag(3)
                }
                .pickerStyle(.inline)
                Divider()
                Toggle("Auto-Goto", isOn: $model.autoGoto)
            }

            stripMenu("DISASTERS") {
                Button("Fire") { model.engine.makeDisaster(0) }
                Button("Flood") { model.engine.makeDisaster(1) }
                Button("Earthquake") { model.engine.makeDisaster(2) }
                Button("Monster") { model.engine.makeDisaster(3) }
                Button("Tornado") { model.engine.makeDisaster(4) }
                Button("Meltdown") { model.engine.makeDisaster(5) }
            }

            stripMenu("WINDOWS") {
                Button("Budget") { model.showBudgetSheet = true }
                Button("Graphs") { openWindow(id: "graphs") }
                Button("Evaluation") { openWindow(id: "evaluation") }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .background(DOS.white)
    }

    private func stripMenu<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        Menu {
            content()
        } label: {
            Text(title)
                .font(DOS.font())
                .foregroundColor(DOS.blue)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .frame(maxWidth: .infinity)
    }
}

/// The white line under the map: the selected tool and its cost, or the
/// reason the last click failed.
struct StatusLine: View {
    @Environment(GameModel.self) var model

    var body: some View {
        HStack {
            if let message = model.toolMessage {
                Text(message).foregroundColor(DOS.red)
            } else {
                Text(ToolSpec.spec(for: model.selectedTool)?.statusText ?? "")
                    .foregroundColor(DOS.black)
            }
            Spacer()
        }
        .font(DOS.font())
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(DOS.white)
        .overlay(Rectangle().stroke(DOS.blue, lineWidth: 2))
    }
}
