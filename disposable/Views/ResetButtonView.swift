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
            Text(Strings.Button.reset)
                .textCase(.uppercase)
                .font(.system(.body, weight: .semibold))
                .tracking(1.0)
                .foregroundStyle(.white)
                .blendMode(.hardLight)
                .opacity(0.8)
        }
        .accessibilityLabel(Strings.Accessibility.resetSessionLabel)
        .alert(Strings.Alert.resetSessionTitle, isPresented: $showingResetPrompt) {
            if #available(iOS 17.0, *) {
                TextField(Strings.Placeholder.newSessionName, text: $newSessionName)
            }
            Button(Strings.Button.cancel, role: .cancel) {
                newSessionName = ""
            }
            Button(Strings.Button.confirm) {
                remainingShots = defaultShotCount
                let trimmed = newSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
                sessionName = trimmed.isEmpty ? Strings.Session.untitled : trimmed
                newSessionName = ""
            }
        } message: {
            Text(String(format: Strings.Message.resetShots(defaultShotCount)))
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 12) {
            ResetButtonView(sessionName: .constant(Strings.Session.untitled), remainingShots: .constant(24))
        }
    }
}
