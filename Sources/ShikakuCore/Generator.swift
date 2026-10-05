import Foundation

public struct GeneratedPuzzle: Sendable {
    public let puzzle: Puzzle
    public let solution: [GridRect]
}

public enum GeneratorError: Error, Equatable, Sendable {
    case couldNotGenerateUniquePuzzle
}

public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

public struct ShikakuGenerator: Sendable {
    public init() {}

    public func generate(rows: Int, columns: Int, seed: UInt64, attempts: Int = 200) throws -> GeneratedPuzzle {
        guard rows > 0, columns > 0 else { throw PuzzleError.invalidDimensions }
        var rng = SplitMix64(seed: seed)
        let solver = ShikakuSolver()

        for _ in 0..<attempts {
            let solution = randomTiling(rows: rows, columns: columns, rng: &rng)
            for _ in 0..<12 {
                let clues = solution.map { rect in
                    let cells = rect.cells
                    let cell = cells[Int.random(in: 0..<cells.count, using: &rng)]
                    return Clue(cell: cell, value: rect.area)
                }
                guard let puzzle = try? Puzzle(rows: rows, columns: columns, clues: clues) else { continue }
                if solver.hasUniqueSolution(puzzle) {
                    return GeneratedPuzzle(puzzle: puzzle, solution: solution)
                }
            }
        }
        throw GeneratorError.couldNotGenerateUniquePuzzle
    }

    private func randomTiling<R: RandomNumberGenerator>(rows: Int, columns: Int, rng: inout R) -> [GridRect] {
        var uncovered = Set((0..<rows).flatMap { row in
            (0..<columns).map { Cell(row: row, column: $0) }
        })
        var result: [GridRect] = []

        while let anchor = uncovered.min() {
            var options: [GridRect] = []
            let maxHeight = min(5, rows - anchor.row)
            let maxWidth = min(5, columns - anchor.column)

            for height in 1...maxHeight {
                for width in 1...maxWidth {
                    let rect = GridRect(
                        top: anchor.row,
                        left: anchor.column,
                        bottom: anchor.row + height - 1,
                        right: anchor.column + width - 1
                    )
                    if rect.cells.allSatisfy({ uncovered.contains($0) }) {
                        options.append(rect)
                    }
                }
            }

            options.sort { lhs, rhs in
                if lhs.area != rhs.area { return lhs.area > rhs.area }
                return lhs.width > rhs.width
            }

            let preferred = Array(options.prefix(max(1, min(options.count, 8))))
            let rect = preferred[Int.random(in: 0..<preferred.count, using: &rng)]
            result.append(rect)
            for cell in rect.cells { uncovered.remove(cell) }
        }

        return result
    }
}
