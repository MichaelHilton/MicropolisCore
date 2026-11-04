import SwiftUI
import MicropolisKit

/// The DOS "Start New City" dialog: a city name and a game level.
struct NewCityView: View {
    @Environment(GameModel.self) var model
    @Environment(\.dismiss) var dismiss

    @State private var name = "HERESVILLE"
    @State private var level: GameLevel = .easy

    var body: some View {
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
