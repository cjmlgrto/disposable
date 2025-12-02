import SwiftUI

struct FlashToggleView: View {
    @Binding var isOn: Bool

    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 8) {
                Text("Flash")
                    .textCase(.uppercase)
                    .font(.system(.body, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(.white)
                    .blendMode(.hardLight)
                    .opacity(0.8)
                Circle()
                    .fill(isOn ? Color.green : Color.black.opacity(0.5))
                    .frame(width: 12, height: 12)
                    .shadow(color: isOn ? Color.green : .clear, radius: 8)
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: 1.0)
                            .foregroundStyle(.clear)
                            .blendMode(.plusLighter)
                            .opacity(isOn ? 1 : 0)
                            
                    }
                    .overlay(alignment: .top) {
                        Circle()
                            .foregroundStyle(.white)
                            .frame(width: 4, height: 4, alignment: .top)
                            .blur(radius: 2)
                            .blendMode(.plusLighter)
                            .padding(.top, 2)
                            .opacity(isOn ? 1 : 0)
                    }
                    .padding(2)
                    .insetContainer(cornerRadius: 16)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Flash")
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        StatefulPreviewWrapper(false) { FlashToggleView(isOn: $0) }
    }
    
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
