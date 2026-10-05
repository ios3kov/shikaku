# Tasks and verification

| ID | Requirement | Implementation | Verification | Status |
| --- | --- | --- | --- | --- |
| T1 | Core Shikaku rules independent of UI | `Sources/ShikakuCore/Models.swift`, `Validator.swift` | validator + solved-state tests | PASS |
| T2 | Every generated puzzle is solver-verified unique | `Solver.swift`, `Generator.swift` | known solution, ambiguity, 20 seeded generations, default difficulty seeds | PASS |
| T3 | Moves support replace-overlap, remove, undo/redo and hints | `GameSession.swift` | session transition + hint tests | PASS |
| T4 | Save/restore does not silently accept structurally corrupt state | `GameSessionSnapshot`, `SessionStore` | snapshot round-trip + corrupt overlap rejection | Core PASS; iOS file I/O NOT_RUN |
| T5 | Native playable board | `App/Shikaku/BoardView.swift`, `GameScreen.swift` | Xcode build + simulator/device interaction | NOT_RUN |
| T6 | Accessible non-drag path for core move | `AccessibleMoveSheet.swift` | VoiceOver task completion on device | NOT_RUN |
| T7 | Autosave and timer lifecycle | `GameViewModel.swift`, `SessionStore.swift` | background/foreground + termination/restore on device | NOT_RUN |
| T8 | Openable iOS project without external generator | `Shikaku.xcodeproj` + shared scheme | pbxproj plist lint + scheme XML parse; Xcode build | Static PASS; Xcode NOT_RUN |
