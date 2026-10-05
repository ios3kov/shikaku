import Foundation

public enum RectangleIssue: Equatable, Sendable {
    case outOfBounds
    case wrongClueCount(Int)
    case wrongArea(expected: Int, actual: Int)
}

public struct RectangleValidation: Equatable, Sendable {
    public let rectangle: GridRect
    public let issue: RectangleIssue?

    public var isValid: Bool { issue == nil }
}

public enum SolutionIssue: Equatable, Sendable {
    case invalidRectangle(index: Int, issue: RectangleIssue)
    case overlap(first: Int, second: Int)
    case uncoveredCells(Int)
}

public struct ShikakuValidator: Sendable {
    public init() {}

    public func validate(_ rect: GridRect, in puzzle: Puzzle) -> RectangleValidation {
        guard puzzle.isInside(rect) else {
            return RectangleValidation(rectangle: rect, issue: .outOfBounds)
        }
        let clues = puzzle.clues.filter { rect.contains($0.cell) }
        guard clues.count == 1 else {
            return RectangleValidation(rectangle: rect, issue: .wrongClueCount(clues.count))
        }
        let clue = clues[0]
        guard rect.area == clue.value else {
            return RectangleValidation(rectangle: rect, issue: .wrongArea(expected: clue.value, actual: rect.area))
        }
        return RectangleValidation(rectangle: rect, issue: nil)
    }

    public func solutionIssues(rectangles: [GridRect], puzzle: Puzzle) -> [SolutionIssue] {
        var issues: [SolutionIssue] = []
        for (index, rect) in rectangles.enumerated() {
            if let issue = validate(rect, in: puzzle).issue {
                issues.append(.invalidRectangle(index: index, issue: issue))
            }
        }

        for first in rectangles.indices {
            for second in rectangles.indices where second > first {
                if rectangles[first].overlaps(rectangles[second]) {
                    issues.append(.overlap(first: first, second: second))
                }
            }
        }

        let covered = Set(rectangles.flatMap(\.cells))
        let missing = puzzle.area - covered.count
        if missing > 0 {
            issues.append(.uncoveredCells(missing))
        }
        return issues
    }

    public func isSolved(rectangles: [GridRect], puzzle: Puzzle) -> Bool {
        solutionIssues(rectangles: rectangles, puzzle: puzzle).isEmpty
    }
}
