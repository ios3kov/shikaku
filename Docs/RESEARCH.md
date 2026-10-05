# Architecture research — 2026-10-05

## Question

How should a native iOS Shikaku board be modeled so that game rules, generation, rendering and accessibility remain independently verifiable?

## Sources checked

- Apple SwiftUI Canvas: https://developer.apple.com/documentation/swiftui/canvas
- Apple SwiftUI Grid: https://developer.apple.com/documentation/swiftui/grid
- Apple SwiftUI accessibility fundamentals: https://developer.apple.com/documentation/swiftui/accessibility-fundamentals
- Nikoli Shikaku rules: https://www.nikoli.co.jp/en/puzzles/shikaku/
- Public implementation notes on exact-cover modeling: https://github.com/sen-ltd/shikaku

## Findings

- Nikoli's canonical rule is a full-grid partition into rectangles, each containing exactly one number equal to the rectangle area.
- A rectangle-domain solver is a natural model: enumerate legal rectangles per clue, then choose one per clue without overlap and require complete coverage.
- Uniqueness must be verified separately from generation; a generated-looking board is not evidence of a unique puzzle.
- SwiftUI Canvas is suitable for drawing but Apple documents that Canvas does not expose per-element interaction/accessibility. Therefore the app should not make Canvas the only semantic representation of cells and game actions.

## Decision

- Keep `ShikakuCore` pure Swift with no SwiftUI dependency.
- Model solver state as rectangle candidates per clue.
- Count solutions with an early stop at two for uniqueness verification.
- Generate a solved rectangular tiling first, place clues, and accept only boards the solver proves unique.
- Render the board natively in SwiftUI, but expose accessible semantic controls/state separately from any custom drawing layer.

## Alternatives considered

- Cell-color/state solver: rejected because the primary unknown is the rectangle assignment, not whether a cell is covered.
- Canvas-only gameplay: rejected because it would make per-cell accessibility and interaction semantics harder to verify.
- Third-party puzzle engine: rejected for MVP; unnecessary dependency and weaker ownership of core rules.
