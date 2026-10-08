import SwiftUI
import MicropolisKit

/// The DOS graph window: six toggles for the history series, a 10-year or
/// 120-year range, and a line chart with years along the bottom.
struct GraphsView: View {
    @Environment(GameModel.self) var model

    @State private var shown: Set<HistoryKind> = Set(HistoryKind.allCases)
    @State private var longRange = false

    var body: some View {
        VStack(spacing: 0) {
            DOSWindowTitle(longRange ? "Last 120 years" : "Last 10 years")
            HStack(alignment: .top, spacing: 0) {
                controls
                chart
            }
        }
        .background(DOS.lightGray)
        .font(DOS.font())
        .fixedSize()
    }

    private var controls: some View {
        Grid(horizontalSpacing: 3, verticalSpacing: 3) {
            ForEach(0..<3) { row in
                GridRow {
                    ForEach(HistoryKind.allCases[(row * 2)..<(row * 2 + 2)], id: \.self) { kind in
                        seriesButton(kind)
                    }
                }
            }
            GridRow {
                Button { longRange = false } label: { DOSButtonLabel("10 YR", selected: !longRange) }
                    .buttonStyle(.plain)
                Button { longRange = true } label: { DOSButtonLabel("120 YR", selected: longRange) }
                    .buttonStyle(.plain)
            }
        }
        .padding(4)
    }

    private func seriesButton(_ kind: HistoryKind) -> some View {
        Button {
            if shown.contains(kind) { shown.remove(kind) } else { shown.insert(kind) }
        } label: {
            Text(GraphSeries.shortName(kind))
                .font(DOS.font(11))
                .foregroundColor(GraphSeries.color(kind))
                .frame(width: 58, height: 26)
                .background(DOS.black)
                .overlay(Rectangle().strokeBorder(shown.contains(kind) ? DOS.yellow : DOS.darkGray,
                                            lineWidth: shown.contains(kind) ? 3 : 2))
        }
        .buttonStyle(.plain)
        .help(GraphSeries.name(kind))
    }

    private var chart: some View {
        // historyVersion is read so the chart redraws when the engine adds data.
        let _ = model.historyVersion
        let series = GraphSeries.series(engine: model.engine, kinds: shown, longRange: longRange)
        return VStack(spacing: 0) {
            Canvas { context, size in
                drawGrid(context, size)
                for (kind, values) in series {
                    context.stroke(GraphSeries.path(values, in: size), with: .color(GraphSeries.color(kind)), lineWidth: 2)
                }
            }
            .frame(width: 360, height: 180)
            .background(DOS.white)
            HStack {
                ForEach(Array(GraphSeries.yearLabels(year: model.year, longRange: longRange).enumerated()), id: \.offset) { i, label in
                    if i > 0 { Spacer() }
                    Text(label)
                }
            }
            .font(DOS.font(11))
            .foregroundColor(DOS.blue)
            .frame(width: 360)
        }
        .padding(4)
    }

    private func drawGrid(_ context: GraphicsContext, _ size: CGSize) {
        var grid = Path()
        for i in 1..<10 {
            let x = size.width * CGFloat(i) / 10
            grid.move(to: CGPoint(x: x, y: 0))
            grid.addLine(to: CGPoint(x: x, y: size.height))
        }
        context.stroke(grid, with: .color(DOS.lightBlue.opacity(0.5)), lineWidth: 1)
    }
}

/// Graph data shaping, kept apart from the view so it can be tested.
enum GraphSeries {
    static func name(_ kind: HistoryKind) -> String {
        switch kind {
        case .residential: "Residential"
        case .commercial: "Commercial"
        case .industrial: "Industrial"
        case .money: "Cash Flow"
        case .crime: "Crime"
        case .pollution: "Pollution"
        }
    }

    static func shortName(_ kind: HistoryKind) -> String {
        switch kind {
        case .residential: "RES"
        case .commercial: "COM"
        case .industrial: "IND"
        case .money: "CASH"
        case .crime: "CRIME"
        case .pollution: "POLL"
        }
    }

    static func color(_ kind: HistoryKind) -> Color {
        switch kind {
        case .residential: DOS.green
        case .commercial: DOS.lightBlue
        case .industrial: DOS.yellow
        case .money: Color(red: 0, green: 0.67, blue: 0.67)
        case .crime: DOS.red
        case .pollution: Color(red: 0.67, green: 0.33, blue: 0)
        }
    }

    /// Oldest-first values scaled to 0...1. Residential, commercial and
    /// industrial share one scale so they can be compared, as in DOS; the
    /// others are already 0...255 in the engine.
    static func series(engine: Engine, kinds: Set<HistoryKind>, longRange: Bool) -> [(HistoryKind, [Double])] {
        let range = longRange ? 120..<240 : 0..<120
        var raw: [HistoryKind: [Int]] = [:]
        for kind in HistoryKind.allCases where kinds.contains(kind) {
            raw[kind] = Array(engine.history(kind)[range].reversed())
        }
        let zoneMax = max(1, [HistoryKind.residential, .commercial, .industrial]
            .compactMap { raw[$0]?.max() }.max() ?? 1)
        return HistoryKind.allCases.compactMap { kind in
            guard let values = raw[kind] else { return nil }
            let top = [.residential, .commercial, .industrial].contains(kind) ? zoneMax : 255
            return (kind, values.map { min(1, max(0, Double($0) / Double(top))) })
        }
    }

    static func path(_ values: [Double], in size: CGSize) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }
        for (i, v) in values.enumerated() {
            let point = CGPoint(x: size.width * CGFloat(i) / CGFloat(values.count - 1),
                                y: size.height * (1 - CGFloat(v)) - 1)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }

    /// Start, middle and end years, as DOS prints them under the graph.
    static func yearLabels(year: Int, longRange: Bool) -> [String] {
        let span = longRange ? 120 : 10
        return [year - span, year - span / 2, year].map(String.init)
    }
}
