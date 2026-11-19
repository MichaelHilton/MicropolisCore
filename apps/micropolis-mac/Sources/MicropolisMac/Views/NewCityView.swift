import SwiftUI
import MicropolisKit

/// The DOS "Start New City" dialog: a city name and a game level.
struct NewCityView: View {
    @Environment(GameModel.self) var model
    @Environment(\.dismiss) var dismiss

    @State private var name = "HERESVILLE"
    @State private var level: GameLevel = .easy

    var body: some View {
        if let theme = model.graphicsPackage.chrome { themed(theme) } else { dosBody }
    }

    /// The same dialog in a themed window. Identifiers match the DOS layout.
    private func themed(_ theme: ChromeTheme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(theme.label("Start a New City")).font(theme.font(18)).foregroundStyle(theme.heading)
            Text("City name").font(theme.font(11)).foregroundStyle(theme.ink.opacity(0.7))
            TextField("", text: $name)
                .textFieldStyle(.plain)
                .padding(6)
                .background(theme.cornerShape.fill(theme.card))
                .overlay(theme.cornerShape.stroke(theme.cardBorder, lineWidth: 1))
                .accessibilityIdentifier("newCity.name")

            Text("Game level").font(theme.font(11)).foregroundStyle(theme.ink.opacity(0.7))
            HStack(spacing: 6) {
                ForEach(GameLevel.allCases, id: \.self) { option in
                    let selected = level == option
                    Button { level = option } label: {
                        Text(EvaluationText.levelName(option.rawValue))
                            .frame(maxWidth: .infinity).padding(.vertical, 6)
                            .foregroundStyle(selected ? theme.onAccent : theme.ink)
                            .background(theme.cornerShape.fill(selected ? theme.accentFill : theme.card))
                            .overlay(theme.cornerShape.stroke(selected ? theme.accentFill : theme.cardBorder, lineWidth: 1))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("newCity.level.\(option.rawValue)")
                    .accessibilityValue(selected ? "1" : "0")
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("newCity.cancel")
                Button {
                    model.newCity(name: name, level: level)
                    dismiss()
                } label: {
                    Text("Start").themedPrimary(theme)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("newCity.ok")
            }
        }
        .padding(18)
        .frame(width: 320)
        .themedWindow(theme)
    }

    private var dosBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SIMCITY city name:")
            TextField("", text: $name)
                .textFieldStyle(.plain)
                .padding(4)
                .foregroundColor(DOS.lightBlue)
                .overlay(Rectangle().stroke(Color(red: 0.67, green: 1, blue: 1), lineWidth: 2))
                .accessibilityIdentifier("newCity.name")

            Text("Game Play Level").frame(maxWidth: .infinity)
            ForEach(GameLevel.allCases, id: \.self) { option in
                Button { level = option } label: {
                    HStack {
                        Rectangle()
                            .fill(level == option ? DOS.blue : Color(red: 0.67, green: 1, blue: 1))
                            .padding(level == option ? 5 : 0)
                            .frame(width: 18, height: 22)
                            .overlay(Rectangle().stroke(DOS.blue, lineWidth: 2))
                        Text(EvaluationText.levelName(option.rawValue))
                    }
                }
                .buttonStyle(.plain)
                .padding(.leading, 40)
                .accessibilityIdentifier("newCity.level.\(option.rawValue)")
                .accessibilityValue(level == option ? "1" : "0")
            }

            Button {
                model.newCity(name: name, level: level)
                dismiss()
            } label: {
                Text("OK")
                    .padding(.horizontal, 6)
                    .background(Color(red: 0.67, green: 1, blue: 1))
                    .overlay(Rectangle().stroke(DOS.blue, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("newCity.ok")

            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
                .hidden()
                .frame(height: 0)
                .accessibilityIdentifier("newCity.cancel")
        }
        .font(DOS.font(15))
        .foregroundColor(DOS.blue)
        .padding(16)
        .frame(width: 300)
        .background(DOS.white)
        .overlay(Rectangle().stroke(DOS.lightBlue, lineWidth: 6))
    }
}
