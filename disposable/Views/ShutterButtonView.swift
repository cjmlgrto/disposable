import SwiftUI
import UIKit

struct ShutterButtonView: View {
    var action: () -> Void

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.prepare()
            impact.impactOccurred()
            action()
        } label: {
            Circle()
                .frame(width: 80, height: 80)
                .glassEffect(.clear)
                .tint(.yellow)
        }
        .accessibilityLabel("Shutter")
        .padding(8)
        .insetContainer(cornerRadius: 88)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            ShutterButtonView(action: {})
        }
    }
}
