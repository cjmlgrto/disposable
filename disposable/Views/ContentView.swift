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
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .insetContainer(cornerRadius: 48)
                    

                    // Fixed spacing between reset and flash
                    Spacer()
                    
                    // Flash toggle
                    FlashToggleView(isOn: $camera.flashEnabled)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .insetContainer(cornerRadius: 48)
                }
                .padding(24)
                .headerContainerStyle(cornerRadius: 0)

                Spacer()
                
                VStack(spacing: 24) {
                    // Counter display
                    CounterView(value: camera.remainingShots)
                    
                    // Session name display
                    SessionNameView(name: camera.sessionName)
                        .rotationEffect(.degrees(-4))
                }

                Spacer()
                
                HStack() {
                    // Shutter button
                    ShutterButtonView {
                        camera.capturePhoto()
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity)
                .controlsContainerStyle(cornerRadius: 0)
                
            }
            .cameraContainerStyle(cornerRadius: 48)
            .clipShape(RoundedRectangle(cornerRadius: 48))
            .padding(16)
            .safeAreaPadding(.top)
            .overlay(
                RoundedRectangle(cornerRadius: 48)
                    .stroke(Color.black.opacity(1), lineWidth: 12)
                    .blur(radius: 2)
                    .mask(
                        RoundedRectangle(cornerRadius: 48)
                            .fill(LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .top, endPoint: .bottom))
                    )
                    .blendMode(.overlay)
            )
            
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
