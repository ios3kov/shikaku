import SwiftUI

struct BoardView: View {
    let puzzle: Puzzle
    let rectangles: [GridRect]
    let preview: GridRect?
    let hintedRectangle: GridRect?
    let onPreview: (GridRect?) -> Void
    let onCommit: (GridRect) -> Void
    let onRemove: (Cell) -> Void

    @State private var dragStart: Cell?

    var body: some View {
        GeometryReader { proxy in
            let metrics = BoardMetrics(size: proxy.size, rows: puzzle.rows, columns: puzzle.columns)

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color(uiColor: .systemBackground))
                    .frame(width: metrics.boardWidth, height: metrics.boardHeight)
                    .offset(x: metrics.origin.x, y: metrics.origin.y)

                gridPath(metrics: metrics)
                    .stroke(Color.secondary.opacity(0.45), lineWidth: 1)

                ForEach(Array(rectangles.enumerated()), id: \.offset) { _, rectangle in
                    rectangleOverlay(rectangle, metrics: metrics)
                }

                if let preview {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.opacity(0.14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.accentColor, lineWidth: 2)
                        }
                        .frame(
                            width: CGFloat(preview.width) * metrics.cellSize,
                            height: CGFloat(preview.height) * metrics.cellSize
                        )
                        .offset(
                            x: metrics.origin.x + CGFloat(preview.left) * metrics.cellSize,
                            y: metrics.origin.y + CGFloat(preview.top) * metrics.cellSize
                        )
                }

                ForEach(puzzle.clues, id: \.self) { clue in
                    Text("\(clue.value)")
                        .font(.system(size: max(15, metrics.cellSize * 0.34), weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .frame(width: metrics.cellSize, height: metrics.cellSize)
                        .offset(
                            x: metrics.origin.x + CGFloat(clue.cell.column) * metrics.cellSize,
                            y: metrics.origin.y + CGFloat(clue.cell.row) * metrics.cellSize
                        )
                        .accessibilityLabel(
                            "Row \(clue.cell.row + 1), column \(clue.cell.column + 1), clue \(clue.value)"
                        )
                }
            }
            .contentShape(Rectangle())
            .gesture(dragGesture(metrics: metrics))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(
                "Shikaku board, \(puzzle.rows) rows by \(puzzle.columns) columns, \(puzzle.clues.count) clues, \(rectangles.count) rectangles placed"
            )
        }
        .aspectRatio(CGFloat(puzzle.columns) / CGFloat(puzzle.rows), contentMode: .fit)
    }

    @ViewBuilder
    private func rectangleOverlay(_ rectangle: GridRect, metrics: BoardMetrics) -> some View {
        let validation = ShikakuValidator().validate(rectangle, in: puzzle)
        let isHint = rectangle == hintedRectangle

        RoundedRectangle(cornerRadius: 6)
            .fill((validation.isValid ? Color.accentColor : Color.red).opacity(0.10))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isHint ? Color.orange : (validation.isValid ? Color.accentColor : Color.red),
                        style: StrokeStyle(
                            lineWidth: isHint ? 4 : 3,
                            dash: validation.isValid ? [] : [6, 4]
                        )
                    )
            }
            .overlay(alignment: .topTrailing) {
                if !validation.isValid {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .padding(4)
                        .accessibilityLabel("Invalid rectangle")
                }
            }
            .frame(
                width: CGFloat(rectangle.width) * metrics.cellSize,
                height: CGFloat(rectangle.height) * metrics.cellSize
            )
            .offset(
                x: metrics.origin.x + CGFloat(rectangle.left) * metrics.cellSize,
                y: metrics.origin.y + CGFloat(rectangle.top) * metrics.cellSize
            )
            .accessibilityHidden(true)
    }

    private func gridPath(metrics: BoardMetrics) -> Path {
        Path { path in
            for row in 0...puzzle.rows {
                let y = metrics.origin.y + CGFloat(row) * metrics.cellSize
                path.move(to: CGPoint(x: metrics.origin.x, y: y))
                path.addLine(to: CGPoint(x: metrics.origin.x + metrics.boardWidth, y: y))
            }
            for column in 0...puzzle.columns {
                let x = metrics.origin.x + CGFloat(column) * metrics.cellSize
                path.move(to: CGPoint(x: x, y: metrics.origin.y))
                path.addLine(to: CGPoint(x: x, y: metrics.origin.y + metrics.boardHeight))
            }
        }
    }

    private func dragGesture(metrics: BoardMetrics) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard let current = metrics.cell(at: value.location) else { return }
                if dragStart == nil {
                    dragStart = current
                }
                guard let start = dragStart else { return }
                onPreview(rectangle(from: start, to: current))
            }
            .onEnded { value in
                defer {
                    dragStart = nil
                    onPreview(nil)
                }

                guard let start = dragStart,
                      let end = metrics.cell(at: value.location) else { return }

                if start == end, rectangles.contains(where: { $0.contains(start) }) {
                    onRemove(start)
                } else {
                    onCommit(rectangle(from: start, to: end))
                }
            }
    }

    private func rectangle(from first: Cell, to second: Cell) -> GridRect {
        GridRect(
            top: min(first.row, second.row),
            left: min(first.column, second.column),
            bottom: max(first.row, second.row),
            right: max(first.column, second.column)
        )
    }
}

private struct BoardMetrics {
    let size: CGSize
    let rows: Int
    let columns: Int

    var cellSize: CGFloat {
        min(size.width / CGFloat(columns), size.height / CGFloat(rows))
    }

    var boardWidth: CGFloat { cellSize * CGFloat(columns) }
    var boardHeight: CGFloat { cellSize * CGFloat(rows) }
    var origin: CGPoint {
        CGPoint(
            x: (size.width - boardWidth) / 2,
            y: (size.height - boardHeight) / 2
        )
    }

    func cell(at point: CGPoint) -> Cell? {
        let x = point.x - origin.x
        let y = point.y - origin.y
        guard x >= 0, y >= 0, x < boardWidth, y < boardHeight else { return nil }
        let column = min(columns - 1, Int(x / cellSize))
        let row = min(rows - 1, Int(y / cellSize))
        return Cell(row: row, column: column)
    }
}
