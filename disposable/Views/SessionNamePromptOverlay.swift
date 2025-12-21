import SwiftUI

/// An overlay for entering a session (roll) name, with a dimmed background, editable text, confirm on return, and a cancel (xmark) button.
struct SessionNamePromptOverlay: View {
    @Binding var text: String
    var placeholder: String
    var onConfirm: () -> Void
    var onCancel: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var background: some View {
        Color.black.opacity(0.8)
            .ignoresSafeArea()
            .transition(.opacity)
            .accessibilityHidden(true)
    }
    
    var confirmButton: some View {
        Button {
            onConfirm()
        } label: {
            ZStack {
                Circle()
                    .frame(width: 40, height: 40)
                    .glassEffect(.clear)
                    .tint(.yellow)
                Image(systemName: "checkmark")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .shadow(radius: 1)
                    .accessibilityLabel(Strings.Button.confirm)
            }
        }
    }
    
    var closeButton: some View {
        Button {
            onCancel()
        } label: {
            ZStack {
                Circle()
                    .frame(width: 40, height: 40)
                    .glassEffect(.clear)
                    .tint(.clear)
                Image(systemName: "xmark")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .shadow(radius: 1)
                    .accessibilityLabel(Strings.Button.cancel)
            }
        }
    }
    
    var ribbon: some View {
        TextField(placeholder, text: $text)
            .multilineTextAlignment(.center)
            .focused($isFocused)
            .textCase(.uppercase)
            .font(.system(size: 20, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white)
            .shadow(radius: 1.0, y: 1.0)
            .padding(.horizontal, 24)
            .padding(.vertical, 4)
            .background(Color(red: 230/255, green: 50/255, blue: 26/255))
            .shadow(color: Color.black.opacity(0.4), radius: 0.5, y: 0.5)
            .overlay(alignment: .top) {
                Rectangle()
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, maxHeight: 1.0)
                    .blur(radius: 0.5)
                    .opacity(0.25)
            }
            .submitLabel(.done)
            .onSubmit {
                onConfirm()
            }
            .accessibilityLabel(Strings.Session.namePrompt)
    }
    
    var body: some View {
        ZStack {
            background

            HStack {
                closeButton
                Spacer()
                ribbon.padding(16)
                Spacer()
                confirmButton
            }
        }
        .safeAreaPadding(.all)
        .onAppear {
            // Automatically focus the text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isFocused = true
            }
        }
    }
}

#if DEBUG
#Preview {
    SessionNamePromptOverlay(
        text: .constant("Street Roll"),
        placeholder: "Name your roll",
        onConfirm: {},
        onCancel: {}
    )
}
#endif
