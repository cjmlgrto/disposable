//
//  ContentView.swift
//  disposable
//
//  Created by Carlos Melegrito on 30/11/2025.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var camera = CameraController()
    @State private var animateKick = false

    var body: some View {
        ZStack {
            // No live preview; keep a simple dark background.
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                // Flash toggle
                Toggle(isOn: $camera.flashEnabled) {
                    Label {
                        Text("Flash")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.yellow)
                    } icon: {
                        Image(systemName: camera.flashEnabled ? "bolt.fill" : "bolt.slash.fill")
                            .foregroundStyle(camera.flashEnabled ? .yellow : .gray)
                    }
                }
                .tint(.yellow)
                .padding(.horizontal)
                .padding(.top, 32)
                .accessibilityLabel("Flash")
                .accessibilityValue(camera.flashEnabled ? "On" : "Off")
                
                Spacer()
                
                // Session name display
                Text(camera.sessionName.isEmpty ? "Untitled" : camera.sessionName)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.yellow)
                    .padding(.top, 24)
                    .accessibilityLabel("Session name")
                    .accessibilityValue(camera.sessionName.isEmpty ? "Untitled" : camera.sessionName)

                // Counter display
                Text("\(camera.remainingShots)")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(.yellow)
                    // Smooth numeric morphing on supported platforms
                    .modifier(NumericTextTransition(value: camera.remainingShots))
                    // Subtle emphasis animation each time the value changes
                    .scaleEffect(animateKick ? 1.1 : 1.0)
                    .opacity(animateKick ? 0.9 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: animateKick)
                    .onChange(of: camera.remainingShots) { _, _ in
                        // Kick the emphasis animation
                        animateKick = true
                        // Reset shortly after to allow retriggering
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            animateKick = false
                        }
                    }

                Spacer()

                Button {
                    // Haptic for shutter press
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.prepare()
                    impact.impactOccurred()

                    camera.capturePhoto()
                } label: {
                    Circle()
                        .strokeBorder(.white, lineWidth: 6)
                        .frame(width: 80, height: 80)
                        .background(Circle().fill(.white.opacity(0.2)))
                        .padding(.bottom, 24)
                }
                .accessibilityLabel("Shutter")
            }
            .padding(.horizontal)
        }
        .task {
            await camera.start()
        }
        .alert(camera.errorMessage ?? "", isPresented: .constant(camera.errorMessage != nil)) {
            Button("OK") { camera.errorMessage = nil }
        }
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
    ContentView()
}
