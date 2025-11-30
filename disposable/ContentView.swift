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

    var body: some View {
        ZStack {
            // No live preview; keep a simple dark background.
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                // Session name display
                Text(camera.sessionName.isEmpty ? "Untitled" : camera.sessionName)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                    .padding(.top, 24)
                    .accessibilityLabel("Session name")
                    .accessibilityValue(camera.sessionName.isEmpty ? "Untitled" : camera.sessionName)

                // Counter display
                Text("\(camera.remainingShots)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)

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

#Preview {
    ContentView()
}
