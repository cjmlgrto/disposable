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
        static let resetSessionTitle = "Reset Session"
        static let permissionsRequired = "Camera and Photo Library permissions are required."
        static let noBackCamera = "No back camera available."
    }

    enum Placeholder {
        static let sessionName = "Session name"
        static let newSessionName = "New session name"
    }

    enum Session {
        static let untitled = "Untitled"
        static let new = "New Session"
        static let namePrompt = "Name this session"
    }

    enum Accessibility {
        static let sessionNameLabel = "Session name"
        static let resetSessionLabel = "Reset session"
    }

    enum Message {
        static func resetShots(_ count: Int) -> String {
            "This will reset remaining shots to \(count). Enter a new session name."
        }
        static func saveFailed(_ reason: String) -> String {
            "Save failed: \(reason)"
        }
    }
}
