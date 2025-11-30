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
                // Counter display
                Text("\(camera.remainingShots)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                    .padding(.top, 24)

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
            .padding()
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
