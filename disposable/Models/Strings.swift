// Strings.swift

import Foundation

enum Strings {
    enum Button {
        static let reset = "Reset"
        static let confirm = "Confirm"
        static let cancel = "Cancel"
        static let ok = "OK"
        static let save = "Save"
        static let shutter = "Shutter"
    }
    
    enum Alert {
        static let resetSessionTitle = "Reset Roll"
        static let permissionsRequired = "Camera and Photo Library permissions are required."
        static let noBackCamera = "Uh oh, no camera found."
    }

    enum Placeholder {
        static let sessionName = "New Roll"
        static let newSessionName = "New Roll"
    }

    enum Session {
        static let untitled = "disposable"
        static let new = "New Roll"
        static let namePrompt = "New Roll"
    }

    enum Accessibility {
        static let sessionNameLabel = "Roll name"
        static let resetSessionLabel = "Reset roll"
    }

    enum Message {
        static func resetShots(_ count: Int) -> String {
            "This will reset remaining shots to \(count). Enter a new roll name."
        }
        static func saveFailed(_ reason: String) -> String {
            "Save failed: \(reason)"
        }
    }
}
