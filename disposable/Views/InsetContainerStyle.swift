import SwiftUI

struct ShadowSpec {
    var color: Color
    var radius: CGFloat
    var x: CGFloat
    var y: CGFloat
    
    static func soft(
        color: Color = .black.opacity(0.25),
        radius: CGFloat = 12,
        x: CGFloat = 0,
        y: CGFloat = 8
    ) -> ShadowSpec {
        ShadowSpec(color: color, radius: radius, x: x, y: y)
    }
    
    static func whiteSubtle(
        color: Color = .white,
        radius: CGFloat = 2,
        x: CGFloat = 0,
        y: CGFloat = 2
    ) -> ShadowSpec {
        ShadowSpec(color: color, radius: radius, x: x, y: y)
    }
}

struct InnerShadowSpec {
    var color: Color
    var radius: CGFloat
    var x: CGFloat
    var y: CGFloat
    
    static func subtleInset(
        color: Color = Color.black.opacity(0.25),
        radius: CGFloat = 2,
        x: CGFloat = 0,
        y: CGFloat = 2
    ) -> InnerShadowSpec {
        InnerShadowSpec(color: color, radius: radius, x: x, y: y)
    }
}

struct InsetContainerStyle: ViewModifier {
    var cornerRadius: CGFloat = 44
    var background: AnyShapeStyle? = nil
    var borderColor: Color = .black
    var borderWidth: CGFloat = 1
    var dropShadows: [ShadowSpec] = [.whiteSubtle()]
    var innerShadows: [InnerShadowSpec] = [.subtleInset()]
    
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        
        content
            .background {
                if let background {
                    shape.fill(background)
                } else {
                    // CSS: background: linear-gradient(180deg, #232216 0%, #19160B 100%);
                    let top = Color(red: 0x23/255.0, green: 0x22/255.0, blue: 0x16/255.0)
                    let bottom = Color(red: 0x19/255.0, green: 0x16/255.0, blue: 0x0B/255.0)
                    let gradient = LinearGradient(
                        colors: [top, bottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    shape.fill(gradient)
                }
            }
            .overlay {
                shape.strokeBorder(Color.black, lineWidth: 1)
            }
            .overlay {
                ZStack {
                    ForEach(Array(innerShadows.enumerated()), id: \.offset) { _, inner in
                        shape
                            .strokeBorder(Color.clear)
                            .shadow(color: inner.color, radius: inner.radius, x: inner.x, y: inner.y)
                            .clipShape(shape)
                            .mask(shape)
                            .blendMode(.multiply)
                    }
                }
            }
            .modifier(DropShadowsModifier(shadows: dropShadows))
    }
}

private struct DropShadowsModifier: ViewModifier {
    let shadows: [ShadowSpec]

    func body(content: Content) -> some View {
        ZStack {
            // Apply each shadow to the same content and stack them
            ForEach(Array(shadows.enumerated()), id: \.offset) { _, shadow in
                content.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
            }
            // Ensure the original content is also present (top-most without extra shadow)
            content
        }
    }
}

extension View {
    func insetContainer(
        cornerRadius: CGFloat = 14,
        background: AnyShapeStyle? = nil,
        useDefaultBackground: Bool = true,
        borderColor: Color = .white.opacity(0.12),
        borderWidth: CGFloat = 1,
        dropShadows: [ShadowSpec] = [.soft()],
        innerShadows: [InnerShadowSpec] = []
    ) -> some View {
        let bg: AnyShapeStyle? = useDefaultBackground ? nil : background
        return self.modifier(
            InsetContainerStyle(
                cornerRadius: cornerRadius,
                background: bg,
                borderColor: borderColor,
                borderWidth: borderWidth,
                dropShadows: dropShadows,
                innerShadows: innerShadows
            )
        )
    }
    
    func insetContainerNeutral(cornerRadius: CGFloat = 44) -> some View {
        return insetContainer(
            cornerRadius: cornerRadius,
            useDefaultBackground: true,
            borderColor: .black,
            borderWidth: 1,
            dropShadows: [.whiteSubtle()],
            innerShadows: [.subtleInset()]
        )
    }
    
    func insetContainerEmphasis(cornerRadius: CGFloat = 44) -> some View {
        return insetContainer(
            cornerRadius: cornerRadius,
            useDefaultBackground: true,
            borderColor: .black,
            borderWidth: 1,
            dropShadows: [.whiteSubtle()],
            innerShadows: [.subtleInset()]
        )
    }
}

struct InsetContainer<Content: View>: View {
    var cornerRadius: CGFloat = 44
    var background: AnyShapeStyle? = nil
    var borderColor: Color = .black
    var borderWidth: CGFloat = 1
    var dropShadows: [ShadowSpec] = [.whiteSubtle()]
    var innerShadows: [InnerShadowSpec] = [.subtleInset()]
    @ViewBuilder var content: () -> Content
    
    init(
        cornerRadius: CGFloat = 44,
        background: AnyShapeStyle? = nil,
        borderColor: Color = .black,
        borderWidth: CGFloat = 1,
        dropShadows: [ShadowSpec] = [.whiteSubtle()],
        innerShadows: [InnerShadowSpec] = [.subtleInset()],
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.background = background
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.dropShadows = dropShadows
        self.innerShadows = innerShadows
        self.content = content
    }
    
    var body: some View {
        content()
            .modifier(
                InsetContainerStyle(
                    cornerRadius: cornerRadius,
                    background: background,
                    borderColor: borderColor,
                    borderWidth: borderWidth,
                    dropShadows: dropShadows,
                    innerShadows: innerShadows
                )
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            Button("Reset") {}
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .insetContainerNeutral()
            
            Toggle(isOn: .constant(true)) {
                Text("Enable")
            }
            .toggleStyle(.switch)
            .insetContainerNeutral()
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        
        HStack(spacing: 16) {
            Button("Reset") {}
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .insetContainerEmphasis()
            
            Toggle(isOn: .constant(false)) {
                Text("Enable")
            }
            .toggleStyle(.switch)
            .insetContainerEmphasis()
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
    }
    .padding(40)
    .background(Color(.systemBackground))
}
