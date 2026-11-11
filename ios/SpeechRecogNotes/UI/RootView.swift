import SwiftUI

struct RootView: View {
    @Environment(VoiceNoteController.self) private var controller

    var body: some View {
        NavigationStack {
            NotesListView()
        }
        .onAppear {
            controller.loadIfNeeded()
            controller.preparePermissions()
        }
    }
}
