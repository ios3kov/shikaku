import SwiftUI

@main
struct ShikakuApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = GameViewModel()

    var body: some Scene {
        WindowGroup {
            GameScreen(model: model)
                .onAppear {
                    model.startTimer()
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active:
                        model.startTimer()
                    case .inactive, .background:
                        model.pauseAndSave()
                    @unknown default:
                        model.pauseAndSave()
                    }
                }
        }
    }
}
