import SwiftUI

struct SessionNameView: View {
    let name: String

    private var displayName: String { name.isEmpty ? "Untitled" : name }

    var body: some View {
        Text(displayName)
            .textCase(.uppercase)
            .font(.system(size: 20, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white)
            .accessibilityLabel("Session name")
            .accessibilityValue(displayName)
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
    }
}

#Preview {
    VStack(spacing: 12) {
        SessionNameView(name: "")
        SessionNameView(name: "Street Roll")
    }
}
