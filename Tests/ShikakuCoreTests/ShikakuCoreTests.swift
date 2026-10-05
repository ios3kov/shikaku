import Foundation
import Testing
@testable import ShikakuCore

@Test func candidateEnumerationForForcedRows() throws {
    let puzzle = try Puzzle(rows: 2, columns: 3, clues: [
        Clue(cell: Cell(row: 0, column: 0), value: 3),
        Clue(cell: Cell(row: 1, column: 2), value: 3)
    ])
    let solver = ShikakuSolver()

    #expect(solver.candidates(for: puzzle.clues[0], in: puzzle) == [
        GridRect(top: 0, left: 0, bottom: 0, right: 2)
    ])
    #expect(solver.hasUniqueSolution(puzzle))
}

@Test func validatorRejectsWrongArea() throws {
    let puzzle = try Puzzle(rows: 2, columns: 2, clues: [
        Clue(cell: Cell(row: 0, column: 0), value: 4)
    ])
    let result = ShikakuValidator().validate(
        GridRect(top: 0, left: 0, bottom: 0, right: 1),
        in: puzzle
    )
    #expect(result.issue == .wrongArea(expected: 4, actual: 2))
}

@Test func solverFindsKnownSolution() throws {
    let puzzle = try Puzzle(rows: 2, columns: 3, clues: [
        Clue(cell: Cell(row: 0, column: 0), value: 3),
        Clue(cell: Cell(row: 1, column: 2), value: 3)
    ])
    let solutions = ShikakuSolver().solve(puzzle, limit: 2)
    #expect(solutions.count == 1)
    #expect(ShikakuValidator().isSolved(rectangles: solutions[0], puzzle: puzzle))
}

@Test func generatorProducesUniquePuzzle() throws {
    let generated = try ShikakuGenerator().generate(rows: 6, columns: 6, seed: 42, attempts: 400)
    #expect(generated.puzzle.rows == 6)
    #expect(generated.puzzle.columns == 6)
    #expect(ShikakuSolver().hasUniqueSolution(generated.puzzle))
    #expect(ShikakuValidator().isSolved(rectangles: generated.solution, puzzle: generated.puzzle))
}

@Test func puzzleRejectsWrongClueSum() {
    #expect(throws: PuzzleError.clueAreaMismatch(expected: 4, actual: 3)) {
        _ = try Puzzle(rows: 2, columns: 2, clues: [
            Clue(cell: Cell(row: 0, column: 0), value: 3)
        ])
    }
}

@Test func solverDetectsAmbiguity() throws {
    let puzzle = try Puzzle(rows: 2, columns: 2, clues: [
        Clue(cell: Cell(row: 0, column: 0), value: 2),
        Clue(cell: Cell(row: 1, column: 1), value: 2)
    ])
    let solutions = ShikakuSolver().solve(puzzle, limit: 2)
    #expect(solutions.count == 2)
    #expect(!ShikakuSolver().hasUniqueSolution(puzzle))
}

@Test func generatorSeedsRemainSolverVerified() throws {
    for seed in UInt64(1)...UInt64(20) {
        let generated = try ShikakuGenerator().generate(rows: 6, columns: 6, seed: seed, attempts: 400)
        #expect(ShikakuSolver().hasUniqueSolution(generated.puzzle))
        #expect(ShikakuValidator().isSolved(rectangles: generated.solution, puzzle: generated.puzzle))
    }
}

@Test func sessionReplacesIntersectingRectangleAndSupportsUndoRedo() throws {
    let puzzle = try Puzzle(rows: 2, columns: 3, clues: [
        Clue(cell: Cell(row: 0, column: 0), value: 3),
        Clue(cell: Cell(row: 1, column: 2), value: 3)
    ])
    var session = try GameSession(puzzle: puzzle, difficulty: .easy, seed: 1)

    let first = GridRect(top: 0, left: 0, bottom: 0, right: 1)
    let replacement = GridRect(top: 0, left: 0, bottom: 0, right: 2)

    let didApplyFirst = session.apply(first)
    let didApplyReplacement = session.apply(replacement)
    #expect(didApplyFirst)
    #expect(didApplyReplacement)
    #expect(session.rectangles == [replacement])
    let didUndo = session.undo()
    #expect(didUndo)
    #expect(session.rectangles == [first])
    let didRedo = session.redo()
    #expect(didRedo)
    #expect(session.rectangles == [replacement])
}

@Test func sessionHintCorrectsWrongProgress() throws {
    let puzzle = try Puzzle(rows: 2, columns: 3, clues: [
        Clue(cell: Cell(row: 0, column: 0), value: 3),
        Clue(cell: Cell(row: 1, column: 2), value: 3)
    ])
    var session = try GameSession(puzzle: puzzle, difficulty: .easy, seed: 1)
    _ = session.apply(GridRect(top: 0, left: 0, bottom: 1, right: 0))

    let hint = session.nextHint()
    #expect(hint == GridRect(top: 0, left: 0, bottom: 0, right: 2))
    let appliedHint = session.applyHint()
    #expect(appliedHint == hint)
    if let hint {
        #expect(session.rectangles.contains(hint))
    }
}

@Test func sessionSnapshotRoundTripsIncludingHistory() throws {
    let puzzle = try Puzzle(rows: 2, columns: 3, clues: [
        Clue(cell: Cell(row: 0, column: 0), value: 3),
        Clue(cell: Cell(row: 1, column: 2), value: 3)
    ])
    var session = try GameSession(puzzle: puzzle, difficulty: .medium, seed: 99)
    _ = session.apply(GridRect(top: 0, left: 0, bottom: 0, right: 2))
    _ = session.apply(GridRect(top: 1, left: 0, bottom: 1, right: 2))
    session.setElapsedSeconds(42)
    let didUndoBeforeSnapshot = session.undo()
    #expect(didUndoBeforeSnapshot)

    let data = try JSONEncoder().encode(session.snapshot())
    let decoded = try JSONDecoder().decode(GameSessionSnapshot.self, from: data)
    var restored = try GameSession(snapshot: decoded)

    #expect(restored.rectangles == session.rectangles)
    #expect(restored.elapsedSeconds == 42)
    #expect(restored.difficulty == .medium)
    #expect(restored.seed == 99)
    #expect(restored.canRedo)
    let didRedoAfterRestore = restored.redo()
    #expect(didRedoAfterRestore)
    #expect(restored.isSolved)
}

@Test func corruptedSnapshotWithOverlapIsRejected() throws {
    let puzzle = try Puzzle(rows: 2, columns: 2, clues: [
        Clue(cell: Cell(row: 0, column: 0), value: 4)
    ])
    let snapshot = GameSessionSnapshot(
        puzzle: puzzle,
        rectangles: [
            GridRect(top: 0, left: 0, bottom: 0, right: 1),
            GridRect(top: 0, left: 1, bottom: 1, right: 1)
        ],
        undoStack: [],
        redoStack: [],
        elapsedSeconds: 0,
        difficulty: .easy,
        seed: 1
    )

    #expect(throws: GameSessionError.invalidRectangleState) {
        _ = try GameSession(snapshot: snapshot)
    }
}

@Test func defaultDifficultySeedsGenerateUniquePuzzles() throws {
    for difficulty in PuzzleDifficulty.allCases {
        let session = try GameSession.newGame(difficulty: difficulty, seed: 42)
        #expect(ShikakuSolver().hasUniqueSolution(session.puzzle))
    }
}
