//
//  ContentView.swift
//  disposable
//
//  Created by Carlos Melegrito on 30/11/2025.
//

import SwiftUI
import UIKit

// Helper to check first launch and mark as launched
fileprivate func isFirstLaunch() -> Bool {
    let key = "hasLaunchedBefore"
    let first = !UserDefaults.standard.bool(forKey: key)
    if first {
        UserDefaults.standard.set(true, forKey: key)
    }
    return first
}

struct ContentView: View {
    @StateObject private var camera = CameraController()
    @State private var sessionNameDraft: String = ""
    @State private var isResetSessionPromptVisible = false
    @State private var resetSessionNameDraft = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        resetSessionNameDraft = camera.sessionName
                        withAnimation { isResetSessionPromptVisible = true }
                    } label: {
                        Text(Strings.Button.reset)
                            .textCase(.uppercase)
                            .font(.system(.body, weight: .semibold))
                            .tracking(1.0)
                            .foregroundStyle(.white)
                            .blendMode(.hardLight)
                            .opacity(0.8)
                    }
                    .accessibilityLabel(Strings.Accessibility.resetSessionLabel)
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
                    ZStack() {
                        // Live viewfinder
                        CameraPreviewView(session: camera.session)
                            .frame(width: 80, height: 58)
                            .background(Color.black.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .insetContainer(cornerRadius: 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .headerContainerStyle(cornerRadius: 12)
                    
                    Spacer()
                    
                    // Counter display
                    CounterView(value: camera.remainingShots)
                    
                    // Session name display
                    SessionNameView(name: camera.sessionName)
                        .rotationEffect(.degrees(-4))
                }
                .padding(.vertical, 24)

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
            
            if camera.isPresentingSessionNamePrompt {
                SessionNamePromptOverlay(
                    text: $camera.pendingSessionName,
                    placeholder: Strings.Placeholder.sessionName,
                    onConfirm: {
                        camera.confirmSessionNamePrompt()
                    },
                    onCancel: {
                        camera.cancelSessionNamePrompt()
                    }
                )
                .transition(.opacity)
                .zIndex(99)
            }
            
            if isResetSessionPromptVisible {
                SessionNamePromptOverlay(
                    text: $resetSessionNameDraft,
                    placeholder: Strings.Placeholder.newSessionName,
                    onConfirm: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation { isResetSessionPromptVisible = false }
                            camera.remainingShots = 24
                            let trimmed = resetSessionNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            camera.sessionName = trimmed.isEmpty ? Strings.Session.untitled : trimmed
                        }
                    },
                    onCancel: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation { isResetSessionPromptVisible = false }
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .ignoresSafeArea(.keyboard)
        .task {
            await camera.start()
            if isFirstLaunch() {
                await MainActor.run { camera.promptForSessionName() }
            }
        }
        .alert(camera.errorMessage ?? "", isPresented: .constant(camera.errorMessage != nil)) {
            Button(Strings.Button.ok) { camera.errorMessage = nil }
        }
    }
}

#Preview {
    ContentView()
}
