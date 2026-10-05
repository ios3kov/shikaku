# Product contract — Shikaku

## Confirmed

- New standalone game: Shikaku.
- New repository.
- Development follows AS-Development-Rules 4.1.0.

## Derived requirements

- Core rule engine must be independent from UI.
- Every shipped/generated puzzle must have exactly one solution.
- Invalid rectangles must not be accepted as solved state.
- Progress must be representable independently from rendering so save/restore can be added safely.

## Initial development assumptions

These are reversible and do not claim final product approval:

- Native iOS/iPadOS app.
- Swift + SwiftUI.
- Minimum iOS 17 for the first development target.
- Portrait-first; iPad layout supported responsively.
- Offline core game.
- No account, ads, analytics, purchases, notifications or network SDK in MVP.
- English UI first; localization structure retained.

## MVP scope

- New puzzle.
- Difficulty tiers.
- Drag from one cell to another to create a rectangle.
- Replace intersected user rectangles on commit.
- Tap a rectangle to remove it.
- Undo / redo.
- Hint based on solver-backed valid progress.
- Autosave current puzzle and moves.
- Timer and completion state.
- Unique generated boards.
- VoiceOver-readable board state and non-gesture alternative for core actions.

## Non-goals for first checkpoint

- App Store submission.
- Monetization.
- Cloud sync / Game Center.
- Daily online puzzle.
- Social features.

## Acceptance for core engine

1. Solver returns the only legal tiling for a known unique puzzle.
2. Uniqueness check stops after two solutions.
3. Generator only returns a puzzle after uniqueness verification.
4. Independent validator checks rectangle bounds, clue count, area, overlap and full coverage.
5. Core tests pass without UI or network dependencies.
