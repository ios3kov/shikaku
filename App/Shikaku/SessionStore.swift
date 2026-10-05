import Foundation

enum SessionStoreError: Error {
    case applicationSupportUnavailable
}

struct SessionStore {
    private let fileManager: FileManager
    private let fileURL: URL

    init(fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw SessionStoreError.applicationSupportUnavailable
        }
        self.fileURL = base
            .appendingPathComponent("Shikaku", isDirectory: true)
            .appendingPathComponent("current-session.json", isDirectory: false)
    }

    func load() throws -> GameSession? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        let snapshot = try JSONDecoder().decode(GameSessionSnapshot.self, from: data)
        return try GameSession(snapshot: snapshot)
    }

    func save(_ session: GameSession) throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(session.snapshot())
        try data.write(to: fileURL, options: [.atomic])
    }

    func clear() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }
}
