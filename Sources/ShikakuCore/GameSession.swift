import Foundation

public enum PuzzleDifficulty: String, CaseIterable, Codable, Hashable, Sendable {
    case easy
    case medium
    case hard

    public var rows: Int {
        switch self {
        case .easy: 5
        case .medium: 6
        case .hard: 7
        }
    }

    public var columns: Int { rows }
}

public enum GameSessionError: Error, Equatable, Sendable {
    case unsupportedSnapshotVersion(Int)
    case invalidElapsedSeconds
    case invalidRectangleState
}

public struct GameSessionSnapshot: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public let version: Int
    public let puzzle: Puzzle
    public let rectangles: [GridRect]
    public let undoStack: [[GridRect]]
    public let redoStack: [[GridRect]]
    public let elapsedSeconds: Int
    public let difficulty: PuzzleDifficulty
    public let seed: UInt64

    public init(
        version: Int = Self.currentVersion,
        puzzle: Puzzle,
        rectangles: [GridRect],
        undoStack: [[GridRect]],
        redoStack: [[GridRect]],
        elapsedSeconds: Int,
        difficulty: PuzzleDifficulty,
        seed: UInt64
    ) {
        self.version = version
        self.puzzle = puzzle
        self.rectangles = rectangles
        self.undoStack = undoStack
        self.redoStack = redoStack
        self.elapsedSeconds = elapsedSeconds
        self.difficulty = difficulty
        self.seed = seed
    }
}

public struct GameSession: Sendable {
    public let puzzle: Puzzle
    public let difficulty: PuzzleDifficulty
    public let seed: UInt64

    public private(set) var rectangles: [GridRect]
    public private(set) var elapsedSeconds: Int

    private var undoStack: [[GridRect]]
    private var redoStack: [[GridRect]]

    public init(
        puzzle: Puzzle,
        difficulty: PuzzleDifficulty,
        seed: UInt64,
        rectangles: [GridRect] = [],
        elapsedSeconds: Int = 0
    ) throws {
        guard elapsedSeconds >= 0 else { throw GameSessionError.invalidElapsedSeconds }
        guard Self.isStructurallyValid(rectangles, in: puzzle) else {
            throw GameSessionError.invalidRectangleState
        }

        self.puzzle = puzzle
        self.difficulty = difficulty
        self.seed = seed
        self.rectangles = Self.canonical(rectangles)
        self.elapsedSeconds = elapsedSeconds
        self.undoStack = []
        self.redoStack = []
    }

    public init(snapshot: GameSessionSnapshot) throws {
        guard snapshot.version == GameSessionSnapshot.currentVersion else {
            throw GameSessionError.unsupportedSnapshotVersion(snapshot.version)
        }
        guard snapshot.elapsedSeconds >= 0 else { throw GameSessionError.invalidElapsedSeconds }

        let states = [snapshot.rectangles] + snapshot.undoStack + snapshot.redoStack
        guard states.allSatisfy({ Self.isStructurallyValid($0, in: snapshot.puzzle) }) else {
            throw GameSessionError.invalidRectangleState
        }

        self.puzzle = snapshot.puzzle
        self.difficulty = snapshot.difficulty
        self.seed = snapshot.seed
        self.rectangles = Self.canonical(snapshot.rectangles)
        self.elapsedSeconds = snapshot.elapsedSeconds
        self.undoStack = snapshot.undoStack.map(Self.canonical)
        self.redoStack = snapshot.redoStack.map(Self.canonical)
    }

    public static func newGame(difficulty: PuzzleDifficulty, seed: UInt64) throws -> GameSession {
        let generated = try ShikakuGenerator().generate(
            rows: difficulty.rows,
            columns: difficulty.columns,
            seed: seed,
            attempts: 500
        )
        return try GameSession(
            puzzle: generated.puzzle,
            difficulty: difficulty,
            seed: seed
        )
    }

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }
    public var isSolved: Bool {
        ShikakuValidator().isSolved(rectangles: rectangles, puzzle: puzzle)
    }

    public var coveredCellCount: Int {
        Set(rectangles.flatMap(\.cells)).count
    }

    public var progress: Double {
        guard puzzle.area > 0 else { return 0 }
        return Double(coveredCellCount) / Double(puzzle.area)
    }

    public func validation(for rectangle: GridRect) -> RectangleValidation {
        ShikakuValidator().validate(rectangle, in: puzzle)
    }

    @discardableResult
    public mutating func apply(_ rectangle: GridRect) -> Bool {
        guard puzzle.isInside(rectangle) else { return false }

        var next = rectangles.filter { !$0.overlaps(rectangle) }
        next.append(rectangle)
        next = Self.canonical(next)
        guard next != rectangles else { return false }

        recordChange(to: next)
        return true
    }

    @discardableResult
    public mutating func removeRectangle(containing cell: Cell) -> Bool {
        guard let index = rectangles.firstIndex(where: { $0.contains(cell) }) else { return false }
        var next = rectangles
        next.remove(at: index)
        recordChange(to: next)
        return true
    }

    @discardableResult
    public mutating func undo() -> Bool {
        guard let previous = undoStack.popLast() else { return false }
        redoStack.append(rectangles)
        rectangles = previous
        return true
    }

    @discardableResult
    public mutating func redo() -> Bool {
        guard let next = redoStack.popLast() else { return false }
        undoStack.append(rectangles)
        rectangles = next
        return true
    }

    public mutating func setElapsedSeconds(_ value: Int) {
        elapsedSeconds = max(0, value)
    }

    public func nextHint() -> GridRect? {
        guard let solution = ShikakuSolver().solve(puzzle, limit: 1).first else { return nil }
        let solutionSet = Set(solution)
        let currentSet = Set(rectangles)

        if let wrong = rectangles.first(where: { !solutionSet.contains($0) }),
           let correction = solution.first(where: { $0.overlaps(wrong) }) {
            return correction
        }

        return solution.first(where: { !currentSet.contains($0) })
    }

    @discardableResult
    public mutating func applyHint() -> GridRect? {
        guard let hint = nextHint() else { return nil }
        _ = apply(hint)
        return hint
    }

    public func snapshot() -> GameSessionSnapshot {
        GameSessionSnapshot(
            puzzle: puzzle,
            rectangles: rectangles,
            undoStack: undoStack,
            redoStack: redoStack,
            elapsedSeconds: elapsedSeconds,
            difficulty: difficulty,
            seed: seed
        )
    }

    private mutating func recordChange(to next: [GridRect]) {
        undoStack.append(rectangles)
        rectangles = Self.canonical(next)
        redoStack.removeAll(keepingCapacity: true)
    }

    private static func canonical(_ rectangles: [GridRect]) -> [GridRect] {
        rectangles.sorted {
            if $0.top != $1.top { return $0.top < $1.top }
            if $0.left != $1.left { return $0.left < $1.left }
            if $0.bottom != $1.bottom { return $0.bottom < $1.bottom }
            return $0.right < $1.right
        }
    }

    private static func isStructurallyValid(_ rectangles: [GridRect], in puzzle: Puzzle) -> Bool {
        guard rectangles.allSatisfy({ puzzle.isInside($0) }) else { return false }
        for first in rectangles.indices {
            for second in rectangles.indices where second > first {
                if rectangles[first].overlaps(rectangles[second]) { return false }
            }
        }
        return true
    }
}
