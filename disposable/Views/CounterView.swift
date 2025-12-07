import SwiftUI

struct CounterView: View {
    let value: Int

    @State private var animateKick = false

    var body: some View {
        ZStack {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .blendMode(.hardLight)
                .opacity(0.8)
                .modifier(NumericTextTransition(value: value))
                .scaleEffect(animateKick ? 1.1 : 1.0)
                .opacity(animateKick ? 0.9 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: animateKick)
                .onChange(of: value) { _, _ in
                    animateKick = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        animateKick = false
                    }
                }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .insetContainer(cornerRadius: 6)
    }
}

// Helper view modifier to use numericText content transition when available
private struct NumericTextTransition: ViewModifier {
    let value: Int
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .contentTransition(.numericText(value: Double(value)))
                .animation(.easeInOut(duration: 0.25), value: value)
        } else {
            content
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CounterView(value: 24)
    }
}
