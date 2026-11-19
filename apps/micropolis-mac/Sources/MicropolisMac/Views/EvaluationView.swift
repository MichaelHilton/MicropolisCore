import SwiftUI
import MicropolisKit

/// The DOS "City Evaluation" window: public opinion on the left, city
/// statistics and the CityScore on the right.
struct EvaluationView: View {
    @Environment(GameModel.self) var model

    var body: some View {
        if let theme = model.graphicsPackage.chrome { themed(theme) } else { dosBody }
    }

    /// The same evaluation in a themed window. Identifiers match the DOS layout.
    private func themed(_ theme: ChromeTheme) -> some View {
        let eval = model.evaluation
        return VStack(alignment: .leading, spacing: 12) {
            Text(theme.label("\(String(model.year)) City Evaluation")).font(theme.font(18)).foregroundStyle(theme.heading)
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    themedHeading(theme.label("Public Opinion"), theme)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Is the mayor doing a good job?")
                        HStack(spacing: 16) {
                            Text("\(eval.yes)% Yes").foregroundStyle(theme.heading)
                            Text("\(100 - eval.yes)% No")
                        }
                    }
                    .frame(width: 280, alignment: .leading).themedCard(theme)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What are the worst problems?")
                        ForEach(Array(eval.problems.enumerated()), id: \.offset) { _, problem in
                            HStack {
                                Text(EvaluationText.problemName(problem.id).capitalized)
                                Spacer()
                                Text("\(problem.votes)%").monospacedDigit()
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(width: 280, alignment: .leading).frame(minHeight: 110).themedCard(theme)
                }
                VStack(alignment: .leading, spacing: 8) {
                    themedHeading(theme.label("Statistics"), theme)
                    VStack(alignment: .leading, spacing: 4) {
                        row("Population", eval.population.formatted(), valueIdentifier: "evaluation.population")
                        row("Net Migration (last year)", eval.populationDelta.formatted())
                        row("Assessed Value", "$" + eval.assessedValue.formatted())
                        row("Category", EvaluationText.className(eval.cityClass).capitalized)
                        row("Game Level", EvaluationText.levelName(eval.gameLevel))
                        Rectangle().fill(theme.cardBorder).frame(height: 1).padding(.vertical, 2)
                        Text("Overall CityScore (0–1000)").foregroundStyle(theme.heading)
                        row("Current score", "Annual change")
                        row("\(eval.score)", "\(eval.scoreDelta)", labelIdentifier: "evaluation.score")
                            .font(theme.font(16))
                    }
                    .frame(width: 280, alignment: .leading).themedCard(theme)
                }
            }
        }
        .padding(16)
        .themedWindow(theme)
        .fixedSize()
        .onAppear { model.evaluation = model.engine.evaluation() }
    }

    private func themedHeading(_ text: String, _ theme: ChromeTheme) -> some View {
        Text(text).font(theme.font(12)).foregroundStyle(theme.heading)
    }

    private var dosBody: some View {
        let eval = model.evaluation
        return VStack(spacing: 10) {
            Text("\(String(model.year)) City Evaluation")
                .foregroundColor(DOS.blue)
                .padding(.horizontal, 6)
                .background(DOS.white)

            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 8) {
                    heading("PUBLIC OPINION")
                    box {
                        Text("Is the mayor doing a good job?")
                        Text("\(eval.yes)% YES").padding(.leading, 40)
                        Text("\(100 - eval.yes)% NO").padding(.leading, 40)
                    }
                    box {
                        Text("What are the worst problems?")
                        ForEach(Array(eval.problems.enumerated()), id: \.offset) { _, problem in
                            Text("\(String(format: "%3d", problem.votes))%  \(EvaluationText.problemName(problem.id))")
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: 110)
                }
                VStack(spacing: 8) {
                    heading("STATISTICS")
                    box {
                        row("Population", eval.population.formatted(), valueIdentifier: "evaluation.population")
                        row("Net Migration", eval.populationDelta.formatted())
                        Text("(last year)").font(DOS.font(10))
                        row("Assessed Value", "$" + eval.assessedValue.formatted())
                        row("Category", EvaluationText.className(eval.cityClass))
                        row("Game Level", EvaluationText.levelName(eval.gameLevel))
                        Text("Overall CityScore").frame(maxWidth: .infinity)
                        Text("(0 - 1000)").font(DOS.font(10)).frame(maxWidth: .infinity)
                        row("current score:", "annual change")
                        row("    \(eval.score)", "\(eval.scoreDelta)    ", labelIdentifier: "evaluation.score")
                    }
                }
            }
        }
        .font(DOS.font())
        .foregroundColor(DOS.blue)
        .padding(12)
        .background(Color(red: 0.67, green: 1, blue: 1))
        .overlay(Rectangle().stroke(DOS.lightBlue, lineWidth: 4))
        .fixedSize()
        .onAppear { model.evaluation = model.engine.evaluation() }
    }

    private func heading(_ text: String) -> some View {
        Text(text)
            .padding(.horizontal, 4)
            .background(DOS.white)
            .overlay(Rectangle().stroke(DOS.lightBlue, lineWidth: 3))
    }

    private func box<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 2, content: content)
            .padding(6)
            .frame(width: 300, alignment: .leading)
            .background(DOS.white)
            .overlay(Rectangle().stroke(DOS.lightBlue, lineWidth: 3))
    }

    private func row(_ label: String, _ value: String,
                     labelIdentifier: String = "", valueIdentifier: String = "") -> some View {
        HStack {
            Text(label)
                .accessibilityIdentifier(labelIdentifier)
            Spacer()
            Text(value)
                .accessibilityIdentifier(valueIdentifier)
        }
    }
}

enum EvaluationText {
    /// Names for the engine's CityVotingProblems, in its order.
    static let problems = ["CRIME", "POLLUTION", "HOUSING COSTS", "TAXES", "TRAFFIC", "UNEMPLOYMENT", "FIRES"]
    static let classes = ["VILLAGE", "TOWN", "CITY", "CAPITAL", "METROPOLIS", "MEGALOPOLIS"]
    static let levels = ["Easy", "Medium", "Hard"]

    static func problemName(_ id: Int) -> String {
        problems.indices.contains(id) ? problems[id] : "?"
    }

    static func className(_ index: Int) -> String {
        classes.indices.contains(index) ? classes[index] : "?"
    }

    static func levelName(_ index: Int) -> String {
        levels.indices.contains(index) ? levels[index] : "?"
    }
}
