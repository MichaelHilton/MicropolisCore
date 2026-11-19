import SwiftUI
import MicropolisKit

/// The DOS graph window: six toggles for the history series, a 10-year or
/// 120-year range, and a line chart with years along the bottom.
struct GraphsView: View {
    @Environment(GameModel.self) var model

    @State private var shown: Set<HistoryKind> = Set(HistoryKind.allCases)
    @State private var longRange = false
    private var theme: ChromeTheme? { model.graphicsPackage.chrome }

    var body: some View {
        VStack(spacing: 0) {
            DOSWindowTitle(longRange ? "Last 120 years" : "Last 10 years")
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(longRange ? "Last 120 years" : "Last 10 years")
                .accessibilityIdentifier("graph.rangeTitle")
            HStack(alignment: .top, spacing: 0) {
                controls
                chart
            }
        }
        .themedOrDOSWindow(theme)
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
                    .accessibilityIdentifier(UIIdentifier.graph("10Year"))
                    .accessibilityValue(longRange ? "off" : "on")
                Button { longRange = true } label: { DOSButtonLabel("120 YR", selected: longRange) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(UIIdentifier.graph("120Year"))
                    .accessibilityValue(longRange ? "on" : "off")
            }
        }
        .padding(4)
    }

    private func seriesButton(_ kind: HistoryKind) -> some View {
        Button {
            if shown.contains(kind) { shown.remove(kind) } else { shown.insert(kind) }
        } label: {
            seriesFace(kind)
        }
        .buttonStyle(.plain)
        .help(GraphSeries.name(kind))
        .accessibilityIdentifier(UIIdentifier.graph(GraphSeries.shortName(kind)))
        .accessibilityValue(shown.contains(kind) ? "on" : "off")
    }

    @ViewBuilder
    private func seriesFace(_ kind: HistoryKind) -> some View {
        if let theme {
            let on = shown.contains(kind)
            HStack(spacing: 4) {
                Circle().fill(on ? GraphSeries.color(kind, theme: theme) : theme.cardBorder).frame(width: 8, height: 8)
                Text(theme.label(GraphSeries.shortName(kind).capitalized)).font(theme.font(11))
            }
            .foregroundStyle(on ? theme.ink : theme.ink.opacity(0.45))
            .frame(width: 64, height: 26)
            .background(theme.cornerShape.fill(on ? theme.selectedFill : theme.card))
            .overlay(theme.cornerShape.stroke(on ? theme.selectedBorder : theme.cardBorder, lineWidth: on ? 1.5 : 1))
        } else {
            Text(GraphSeries.shortName(kind))
                .font(DOS.font(11))
                .foregroundColor(GraphSeries.color(kind))
                .frame(width: 58, height: 26)
                .background(DOS.black)
                .overlay(Rectangle().strokeBorder(shown.contains(kind) ? DOS.yellow : DOS.darkGray,
                                            lineWidth: shown.contains(kind) ? 3 : 2))
        }
    }

    private var chart: some View {
        // historyVersion is read so the chart redraws when the engine adds data.
        let _ = model.historyVersion
        let series = GraphSeries.series(engine: model.engine, kinds: shown, longRange: longRange)
        return VStack(spacing: 0) {
            Canvas { context, size in
                drawGrid(context, size)
                for (kind, values) in series {
                    context.stroke(GraphSeries.path(values, in: size),
                                   with: .color(GraphSeries.color(kind, theme: theme)), lineWidth: 2)
                }
            }
            .frame(width: 360, height: 180)
            .background(theme?.card ?? DOS.white)
            .clipShape(theme?.cornerShape ?? RoundedRectangle(cornerRadius: 0))
            .overlay((theme?.cornerShape ?? RoundedRectangle(cornerRadius: 0)).stroke(theme?.cardBorder ?? .clear))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("City history chart")
            .accessibilityIdentifier("graph.chart")
            HStack {
                ForEach(Array(GraphSeries.yearLabels(year: model.year, longRange: longRange).enumerated()), id: \.offset) { i, label in
                    if i > 0 { Spacer() }
                    Text(label)
                }
            }
            .font(theme?.font(11) ?? DOS.font(11))
            .foregroundStyle(theme?.ink ?? DOS.blue)
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
        context.stroke(grid, with: .color(theme?.cardBorder ?? DOS.lightBlue.opacity(0.5)), lineWidth: 1)
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

    /// Series colors on a themed chart: the zone colors match the demand gauge.
    static func color(_ kind: HistoryKind, theme: ChromeTheme?) -> Color {
        guard let theme else { return color(kind) }
        switch kind {
        case .residential: return theme.demand.r
        case .commercial: return theme.windowScheme == .dark ? theme.demand.c : Color(red: 0.18, green: 0.5, blue: 0.82)
        case .industrial: return theme.windowScheme == .dark ? theme.demand.i : Color(red: 0.85, green: 0.6, blue: 0.1)
        case .money: return Color(red: 0, green: 0.6, blue: 0.6)
        case .crime: return Color(red: 0.85, green: 0.25, blue: 0.22)
        case .pollution: return Color(red: 0.6, green: 0.38, blue: 0.2)
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
