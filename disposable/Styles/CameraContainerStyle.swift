import SwiftUI

/// A reusable ViewModifier that styles a view with a camera container appearance:
/// - Vertical linear gradient background from #FFC728 to #CC990A
/// - Multiple inset shadow overlays to simulate inner shadows and highlights
/// - Rounded corners with configurable corner radius (default 48)
public struct CameraContainerStyle: ViewModifier {
    /// The corner radius for the rounded rectangle container. Default is 48.
    public var cornerRadius: CGFloat = 48

    public func body(content: Content) -> some View {
        content
            .padding(0)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#FFC728"),
                                Color(hex: "#CC990A")
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    // White inner highlight stroke overlay with slight opacity
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .inset(by: 1)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    // Secondary black inner vignette overlay with stronger blur
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.black.opacity(0.45), lineWidth: 6)
                            .blur(radius: 8)
                            .mask(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .top, endPoint: .bottom))
                            )
                    )
                    // Black blurred stroke overlay with low opacity to simulate inner shadow
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.black.opacity(1), lineWidth: 12)
                            .blur(radius: 12)
                            .mask(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .top, endPoint: .bottom))
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
    }
}

public extension View {
    /// Applies the CameraContainerStyle to the view, giving it a stylized container with
    /// a vertical gradient background, inset shadows, and rounded corners.
    /// - Parameter cornerRadius: The corner radius of the container. Default is 48.
    /// - Returns: A view modified with the camera container style.
    func cameraContainerStyle(cornerRadius: CGFloat = 48) -> some View {
        self.modifier(CameraContainerStyle(cornerRadius: cornerRadius))
    }
}

fileprivate extension Color {
    /// Initializes a Color from a hex string of the form "#RRGGBB".
    /// Returns .clear if the string is invalid.
    /// - Parameter hex: A hex color string in the format "#RRGGBB"
    init(hex: String) {
        let r, g, b: Double
        if hex.hasPrefix("#") && hex.count == 7 {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            if scanner.scanHexInt64(&hexNumber) {
                r = Double((hexNumber & 0xFF0000) >> 16) / 255
                g = Double((hexNumber & 0x00FF00) >> 8) / 255
                b = Double(hexNumber & 0x0000FF) / 255
                self = Color(red: r, green: g, blue: b)
                return
            }
        }
        self = .clear
    }
}
