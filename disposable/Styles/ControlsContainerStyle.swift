import SwiftUI

struct InnerShadow<S: Shape>: View {
    var shape: S
    var color: Color = .black
    var radius: CGFloat
    var x: CGFloat = 0
    var y: CGFloat = 0

    var body: some View {
        shape
            .stroke(color.opacity(1), lineWidth: radius * 2)
            .blur(radius: radius)
            .offset(x: x, y: y)
            .mask(
                shape
                    .fill(style: FillStyle(eoFill: true))
            )
            .compositingGroup()
            .blendMode(.overlay)
    }
}

struct ControlsContainerStyle: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(0)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color(hex: 0x2D2C20), location: 0),
                                .init(color: Color(hex: 0x232015), location: 1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                ZStack {
                    InnerShadow(
                        shape: RoundedRectangle(cornerRadius: cornerRadius),
                        color: Color.white.opacity(0.5),
                        radius: 1,
                        x: 0,
                        y: 1
                    )
                    InnerShadow(
                        shape: RoundedRectangle(cornerRadius: cornerRadius),
                        color: Color.white.opacity(0.7),
                        radius: 4,
                        x: 0,
                        y: 0.5
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.7), radius: 0.5, x: 0, y: -0.5)
            .shadow(color: Color.black.opacity(0.5), radius: 0, x: 0, y: -1)
    }
}

public extension View {
    func controlsContainerStyle(cornerRadius: CGFloat = 24) -> some View {
        modifier(ControlsContainerStyle(cornerRadius: cornerRadius))
    }
}

// MARK: - Helpers

fileprivate extension Color {
    init(hex: UInt32) {
        let r = Double((hex & 0xFF0000) >> 16) / 255
        let g = Double((hex & 0x00FF00) >> 8) / 255
        let b = Double(hex & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 40, height: 40)
        Text("Placeholder button")
            .foregroundColor(.white)
            .font(.headline)
        Spacer()
    }
    .padding()
    .controlsContainerStyle(cornerRadius: 24)
    .padding()
    .background(Color.black.edgesIgnoringSafeArea(.all))
}
