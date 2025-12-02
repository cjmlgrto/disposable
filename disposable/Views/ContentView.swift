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
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                // Flash toggle
                FlashToggleView(isOn: $camera.flashEnabled)

                Spacer()

                // Session name display
                SessionNameView(name: camera.sessionName)

                // Counter display
                CounterView(value: camera.remainingShots)

                Spacer()

                // Shutter button
                ShutterButtonView {
                    camera.capturePhoto()
                }

                // Reset button
                ResetButtonView(sessionName: $camera.sessionName, remainingShots: $camera.remainingShots, defaultShotCount: 24)
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
