import SwiftUI

struct GameScreen: View {
    @ObservedObject var model: GameViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                statusBar

                BoardView(
                    puzzle: model.session.puzzle,
                    rectangles: model.session.rectangles,
                    preview: model.previewRectangle,
                    hintedRectangle: model.lastHint,
                    onPreview: { model.previewRectangle = $0 },
                    onCommit: model.commit,
                    onRemove: model.removeRectangle
                )
                .padding(.horizontal, 16)

                controls
            }
            .padding(.vertical, 12)
            .navigationTitle("Shikaku")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { gameToolbar }
            .sheet(isPresented: $model.isShowingAccessibleMove) {
                AccessibleMoveSheet(puzzle: model.session.puzzle, onApply: model.commit)
            }
            .alert("Save problem", isPresented: warningBinding) {
                Button("OK", role: .cancel) {
                    model.persistenceWarning = nil
                }
            } message: {
                Text(model.persistenceWarning ?? "")
            }
            .overlay {
                if model.session.isSolved {
                    completionCard
                }
            }
        }
    }

    private var statusBar: some View {
        HStack {
            Label(model.elapsedText, systemImage: "timer")
                .monospacedDigit()
            Spacer()
            Text("\(Int(model.session.progress * 100))%")
                .monospacedDigit()
                .accessibilityLabel("Progress \(Int(model.session.progress * 100)) percent")
        }
        .font(.headline)
        .padding(.horizontal, 20)
    }

    private var controls: some View {
        HStack(spacing: 18) {
            Button {
                model.undo()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(!model.session.canUndo)

            Button {
                model.redo()
            } label: {
                Label("Redo", systemImage: "arrow.uturn.forward")
            }
            .disabled(!model.session.canRedo)

            Button {
                model.useHint()
            } label: {
                Label("Hint", systemImage: "lightbulb")
            }
            .disabled(model.session.isSolved)
        }
        .labelStyle(.iconOnly)
        .font(.title2)
        .buttonStyle(.bordered)
        .accessibilityElement(children: .contain)
    }

    @ToolbarContentBuilder
    private var gameToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                model.isShowingAccessibleMove = true
            } label: {
                Label("Place Rectangle", systemImage: "rectangle.dashed")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                ForEach(PuzzleDifficulty.allCases, id: \.self) { difficulty in
                    Button(difficulty.title) {
                        model.newGame(difficulty: difficulty)
                    }
                }
            } label: {
                Label("New Puzzle", systemImage: "plus")
            }
        }
    }

    private var completionCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .symbolRenderingMode(.hierarchical)
            Text("Solved")
                .font(.title.bold())
            Text("Time \(model.elapsedText)")
                .monospacedDigit()
            Button("New Puzzle") {
                model.newGame(difficulty: model.session.difficulty)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .shadow(radius: 12)
        .accessibilityElement(children: .combine)
        .accessibilitySortPriority(10)
    }

    private var warningBinding: Binding<Bool> {
        Binding(
            get: { model.persistenceWarning != nil },
            set: { isPresented in
                if !isPresented { model.persistenceWarning = nil }
            }
        )
    }
}

private extension PuzzleDifficulty {
    var title: String {
        switch self {
        case .easy: "Easy · 5×5"
        case .medium: "Medium · 6×6"
        case .hard: "Hard · 7×7"
        }
    }
}
