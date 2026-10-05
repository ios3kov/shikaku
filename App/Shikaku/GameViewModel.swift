import Foundation
import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var session: GameSession
    @Published var previewRectangle: GridRect?
    @Published var lastHint: GridRect?
    @Published var persistenceWarning: String?
    @Published var isShowingAccessibleMove = false

    private let store: SessionStore?
    private var timer: Timer?
    private var ticksSinceSave = 0

    init() {
        let resolvedStore = try? SessionStore()
        var resolvedSession: GameSession?
        var warning: String?

        if let resolvedStore {
            do {
                resolvedSession = try resolvedStore.load()
            } catch {
                warning = "The previous game could not be restored. A new puzzle was created."
            }
        }

        self.store = resolvedStore
        self.session = resolvedSession ?? Self.makeFallbackSession()
        self.persistenceWarning = warning
        save()
    }

    var elapsedText: String {
        let minutes = session.elapsedSeconds / 60
        let seconds = session.elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func startTimer() {
        guard timer == nil, !session.isSolved else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    func pauseAndSave() {
        timer?.invalidate()
        timer = nil
        save()
    }

    func newGame(difficulty: PuzzleDifficulty) {
        do {
            let seed = Self.makeSeed()
            let next = try GameSession.newGame(difficulty: difficulty, seed: seed)
            session = next
            previewRectangle = nil
            lastHint = nil
            save()
            startTimer()
        } catch {
            persistenceWarning = "A new puzzle could not be generated. Your current game was kept."
        }
    }

    func commit(_ rectangle: GridRect) {
        guard session.apply(rectangle) else { return }
        previewRectangle = nil
        lastHint = nil
        save()
        stopTimerIfSolved()
    }

    func removeRectangle(at cell: Cell) {
        guard session.removeRectangle(containing: cell) else { return }
        lastHint = nil
        save()
    }

    func undo() {
        guard session.undo() else { return }
        lastHint = nil
        save()
        startTimer()
    }

    func redo() {
        guard session.redo() else { return }
        lastHint = nil
        save()
        stopTimerIfSolved()
    }

    func useHint() {
        guard let hint = session.applyHint() else { return }
        lastHint = hint
        save()
        stopTimerIfSolved()
    }

    func save() {
        guard let store else { return }
        do {
            try store.save(session)
            ticksSinceSave = 0
        } catch {
            persistenceWarning = "Progress could not be saved."
        }
    }

    private func tick() {
        guard !session.isSolved else {
            pauseAndSave()
            return
        }
        session.setElapsedSeconds(session.elapsedSeconds + 1)
        ticksSinceSave += 1
        if ticksSinceSave >= 5 {
            save()
        }
    }

    private func stopTimerIfSolved() {
        guard session.isSolved else { return }
        pauseAndSave()
    }

    private static func makeFallbackSession() -> GameSession {
        do {
            return try GameSession.newGame(difficulty: .easy, seed: 42)
        } catch {
            preconditionFailure("Tested fallback puzzle generation failed: \(error)")
        }
    }

    private static func makeSeed() -> UInt64 {
        let millis = Date().timeIntervalSince1970 * 1_000
        return UInt64(max(0, millis)) ^ UInt64.random(in: UInt64.min...UInt64.max)
    }
}
