import Foundation

public struct ShikakuSolver: Sendable {
    public init() {}

    public func candidates(for clue: Clue, in puzzle: Puzzle) -> [GridRect] {
        guard clue.value > 0 else { return [] }
        var result = Set<GridRect>()

        for height in 1...puzzle.rows where clue.value % height == 0 {
            let width = clue.value / height
            guard width <= puzzle.columns else { continue }

            let minTop = max(0, clue.cell.row - height + 1)
            let maxTop = min(clue.cell.row, puzzle.rows - height)
            let minLeft = max(0, clue.cell.column - width + 1)
            let maxLeft = min(clue.cell.column, puzzle.columns - width)

            guard minTop <= maxTop, minLeft <= maxLeft else { continue }

            for top in minTop...maxTop {
                for left in minLeft...maxLeft {
                    let rect = GridRect(
                        top: top,
                        left: left,
                        bottom: top + height - 1,
                        right: left + width - 1
                    )
                    let containedClues = puzzle.clues.filter { rect.contains($0.cell) }
                    if containedClues.count == 1, containedClues[0] == clue {
                        result.insert(rect)
                    }
                }
            }
        }
        return result.sorted {
            if $0.top != $1.top { return $0.top < $1.top }
            if $0.left != $1.left { return $0.left < $1.left }
            if $0.bottom != $1.bottom { return $0.bottom < $1.bottom }
            return $0.right < $1.right
        }
    }

    public func solve(_ puzzle: Puzzle, limit: Int = 1) -> [[GridRect]] {
        guard limit > 0 else { return [] }
        let allCandidates = puzzle.clues.map { candidates(for: $0, in: puzzle) }
        guard allCandidates.allSatisfy({ !$0.isEmpty }) else { return [] }

        var solutions: [[GridRect]] = []
        var chosen = Array<GridRect?>(repeating: nil, count: puzzle.clues.count)
        var covered = Set<Cell>()

        func search() {
            if solutions.count >= limit { return }

            var bestIndex: Int?
            var bestFeasible: [GridRect] = []

            for index in puzzle.clues.indices where chosen[index] == nil {
                let feasible = allCandidates[index].filter { rect in
                    rect.cells.allSatisfy { !covered.contains($0) }
                }
                if feasible.isEmpty { return }
                if bestIndex == nil || feasible.count < bestFeasible.count {
                    bestIndex = index
                    bestFeasible = feasible
                    if feasible.count == 1 { break }
                }
            }

            guard let index = bestIndex else {
                let rects = chosen.compactMap { $0 }
                if rects.count == puzzle.clues.count,
                   ShikakuValidator().isSolved(rectangles: rects, puzzle: puzzle) {
                    solutions.append(rects)
                }
                return
            }

            for rect in bestFeasible {
                chosen[index] = rect
                let cells = rect.cells
                covered.formUnion(cells)
                search()
                for cell in cells { covered.remove(cell) }
                chosen[index] = nil
                if solutions.count >= limit { return }
            }
        }

        search()
        return solutions
    }

    public func hasUniqueSolution(_ puzzle: Puzzle) -> Bool {
        solve(puzzle, limit: 2).count == 1
    }
}
