import SwiftUI

struct FlashToggleView: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label {
                Text("Flash")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.yellow)
            } icon: {
                Image(systemName: isOn ? "bolt.fill" : "bolt.slash.fill")
                    .foregroundStyle(isOn ? .yellow : .gray)
            }
        }
        .tint(.yellow)
        .padding(.horizontal)
        .padding(.top, 32)
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
