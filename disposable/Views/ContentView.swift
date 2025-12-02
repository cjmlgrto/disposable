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

            VStack {
                HStack {
                    // Reset button
                    ResetButtonView(
                        sessionName: $camera.sessionName,
                        remainingShots: $camera.remainingShots,
                        defaultShotCount: 24
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .insetContainerNeutral(cornerRadius: 48)

                    // Fixed spacing between reset and flash
                    Spacer()
                    
                    // Flash toggle
                    FlashToggleView(isOn: $camera.flashEnabled)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .insetContainerNeutral(cornerRadius: 48)
                }

                Spacer()
                
                VStack(spacing: 24) {
                    // Counter display
                    CounterView(value: camera.remainingShots)
                    
                    // Session name display
                    SessionNameView(name: camera.sessionName)
                }
                .background(Color.orange.opacity(0.15))

                Spacer()
                
                HStack() {
                    // Shutter button
                    ShutterButtonView {
                        camera.capturePhoto()
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity)
                .background(Color.purple.opacity(0.15))
            }
            .background(Color.red.opacity(0.15))
            .padding(16)
            .safeAreaPadding(.top)
            
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
