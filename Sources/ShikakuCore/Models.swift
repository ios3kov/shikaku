import Foundation

public struct Cell: Hashable, Sendable, Codable, Comparable {
    public let row: Int
    public let column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }

    public static func < (lhs: Cell, rhs: Cell) -> Bool {
        lhs.row == rhs.row ? lhs.column < rhs.column : lhs.row < rhs.row
    }
}

public struct Clue: Hashable, Sendable, Codable {
    public let cell: Cell
    public let value: Int

    public init(cell: Cell, value: Int) {
        self.cell = cell
        self.value = value
    }
}

public struct GridRect: Hashable, Sendable, Codable {
    public let top: Int
    public let left: Int
    public let bottom: Int
    public let right: Int

    public init(top: Int, left: Int, bottom: Int, right: Int) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    public var width: Int { right - left + 1 }
    public var height: Int { bottom - top + 1 }
    public var area: Int { width * height }

    public func contains(_ cell: Cell) -> Bool {
        (top...bottom).contains(cell.row) && (left...right).contains(cell.column)
    }

    public func overlaps(_ other: GridRect) -> Bool {
        !(right < other.left || other.right < left || bottom < other.top || other.bottom < top)
    }

    public var cells: [Cell] {
        var result: [Cell] = []
        result.reserveCapacity(area)
        for row in top...bottom {
            for column in left...right {
                result.append(Cell(row: row, column: column))
            }
        }
        return result
    }
}

public enum PuzzleError: Error, Equatable, Sendable {
    case invalidDimensions
    case clueOutOfBounds(Clue)
    case nonPositiveClue(Clue)
    case clueAreaMismatch(expected: Int, actual: Int)
}

public struct Puzzle: Hashable, Sendable, Codable {
    public let rows: Int
    public let columns: Int
    public let clues: [Clue]

    public init(rows: Int, columns: Int, clues: [Clue], requireAreaSum: Bool = true) throws {
        guard rows > 0, columns > 0 else { throw PuzzleError.invalidDimensions }
        for clue in clues {
            guard clue.value > 0 else { throw PuzzleError.nonPositiveClue(clue) }
            guard clue.cell.row >= 0, clue.cell.row < rows,
                  clue.cell.column >= 0, clue.cell.column < columns else {
                throw PuzzleError.clueOutOfBounds(clue)
            }
        }
        if requireAreaSum {
            let actual = clues.reduce(0) { $0 + $1.value }
            let expected = rows * columns
            guard actual == expected else {
                throw PuzzleError.clueAreaMismatch(expected: expected, actual: actual)
            }
        }
        self.rows = rows
        self.columns = columns
        self.clues = clues.sorted { $0.cell < $1.cell }
    }

    public var area: Int { rows * columns }

    public func isInside(_ rect: GridRect) -> Bool {
        rect.top >= 0 && rect.left >= 0 && rect.bottom < rows && rect.right < columns &&
        rect.top <= rect.bottom && rect.left <= rect.right
    }
}
