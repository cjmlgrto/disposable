import SwiftUI

struct FlashToggleView: View {
    @Binding var isOn: Bool

    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 8) {
                Text("FLASH")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(.white)
                    .blendMode(.hardLight)
                    .opacity(0.8)
                Circle()
                    .fill(isOn ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Flash")
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

#Preview {
    StatefulPreviewWrapper(false) { FlashToggleView(isOn: $0) }
}

// Helper to preview bindings
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View { content($value) }
}
