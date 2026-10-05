# Shikaku

Native iOS/iPadOS Shikaku puzzle game. Development follows `ios3kov/AS-Development-Rules` v4.1.0 pinned to commit `20d1932ded52fed4888d62e384e09452b780f8c2`.

## Current development checkpoint

- Pure Swift rules model and validator.
- Exact-cover-style solver with uniqueness check.
- Deterministic seeded puzzle generator.
- Game session state with replace-overlap moves, remove, undo/redo and solver-backed hints.
- Versioned save snapshot with structural corruption checks.
- SwiftUI board, timer/autosave layer and accessible non-drag move sheet.
- Native `Shikaku.xcodeproj` with shared scheme; no project generator dependency.
- 12 Swift core tests passing on Swift 6.2.1/Linux.

Xcode build, simulator and physical-device checks are still `NOT_RUN` and are not claimed by this checkpoint.

## Rule

Partition the whole grid into axis-aligned rectangles. Each rectangle contains exactly one clue, and that clue equals the rectangle area. Every cell must be covered exactly once.

## Open in Xcode

Open `Shikaku.xcodeproj` and run the `Shikaku` scheme. The current development bundle identifier is `com.ios3kov.shikaku`; signing is automatic and the development team is intentionally not hard-coded.

## Core tests

```bash
swift test
```

Project status and verification mapping live in `Docs/STATUS.md` and `Docs/TASKS.md`.
