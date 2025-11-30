//
//  ContentView.swift
//  disposable
//
//  Created by Carlos Melegrito on 30/11/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var camera = CameraController()

    var body: some View {
        ZStack {
            CameraView(session: camera.session)

            VStack {
                Spacer()
                Button {
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
        }
        .background(Color.black.ignoresSafeArea())
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
