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
                // DOS blanks the funds line while the terrain editor is up.
                Text(model.editMode == .terrain ? " " : "Funds: $\(model.funds.formatted())")
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
    var body: some View {
        HStack(spacing: 0) {
            stripMenu("SYSTEM") { SystemMenuItems() }
            stripMenu("OPTIONS") { OptionsMenuItems() }
            stripMenu("DISASTERS") { DisastersMenuItems() }
            stripMenu("WINDOWS") { WindowsMenuItems() }
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
            } else if model.editMode == .terrain {
                Text(model.terrainFill ? "\(model.terrainTool.name) (Fill)" : model.terrainTool.name)
                    .foregroundColor(DOS.black)
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
