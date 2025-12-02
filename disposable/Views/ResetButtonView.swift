import SwiftUI

struct ResetButtonView: View {
    @Binding var sessionName: String
    @Binding var remainingShots: Int
    var defaultShotCount: Int = 24

    @State private var showingResetPrompt = false
    @State private var newSessionName: String = ""

    var body: some View {
        Button {
            newSessionName = sessionName
            showingResetPrompt = true
        } label: {
            Label("Reset", systemImage: "arrow.counterclockwise")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(.yellow)
                .padding(.bottom, 12)
        }
        .accessibilityLabel("Reset session")
        .alert("Reset Session", isPresented: $showingResetPrompt) {
            if #available(iOS 17.0, *) {
                TextField("New session name", text: $newSessionName)
            }
            Button("Cancel", role: .cancel) {
                newSessionName = ""
            }
            Button("Confirm") {
                remainingShots = defaultShotCount
                let trimmed = newSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
                sessionName = trimmed.isEmpty ? "Untitled" : trimmed
                newSessionName = ""
            }
        } message: {
            Text("This will reset remaining shots to \(defaultShotCount). Enter a new session name.")
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 12) {
            ResetButtonView(sessionName: .constant("Untitled"), remainingShots: .constant(24))
        }
    }
}
