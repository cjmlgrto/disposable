import SwiftUI

struct SessionNameView: View {
    let name: String

    private var displayName: String { name.isEmpty ? "Untitled" : name }

    var body: some View {
        Text(displayName)
            .font(.system(size: 20, weight: .semibold, design: .monospaced))
            .foregroundStyle(.yellow)
            .padding(.top, 24)
            .accessibilityLabel("Session name")
            .accessibilityValue(displayName)
    }
}

#Preview {
    VStack(spacing: 12) {
        SessionNameView(name: "")
        SessionNameView(name: "Street Roll")
    }
    .padding()
    .background(Color.black)
}
