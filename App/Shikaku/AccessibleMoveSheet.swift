import SwiftUI

struct AccessibleMoveSheet: View {
    let puzzle: Puzzle
    let onApply: (GridRect) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startRow = 1
    @State private var startColumn = 1
    @State private var endRow = 1
    @State private var endColumn = 1

    var body: some View {
        NavigationStack {
            Form {
                Section("First corner") {
                    Stepper("Row: \(startRow)", value: $startRow, in: 1...puzzle.rows)
                    Stepper("Column: \(startColumn)", value: $startColumn, in: 1...puzzle.columns)
                }

                Section("Opposite corner") {
                    Stepper("Row: \(endRow)", value: $endRow, in: 1...puzzle.rows)
                    Stepper("Column: \(endColumn)", value: $endColumn, in: 1...puzzle.columns)
                }

                Section {
                    Button("Place rectangle") {
                        onApply(
                            GridRect(
                                top: min(startRow, endRow) - 1,
                                left: min(startColumn, endColumn) - 1,
                                bottom: max(startRow, endRow) - 1,
                                right: max(startColumn, endColumn) - 1
                            )
                        )
                        dismiss()
                    }
                } footer: {
                    Text("This provides a non-drag way to make every move with VoiceOver or other assistive input.")
                }
            }
            .navigationTitle("Place Rectangle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
