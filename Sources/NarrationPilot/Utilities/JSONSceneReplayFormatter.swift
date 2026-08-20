import Foundation

enum JSONSceneReplayFormatter {
    static func spokenText(for scene: NarrationScene) -> String {
        var parts: [String] = []

        if let action = scene.onScreen.action?.trimmingCharacters(in: .whitespacesAndNewlines),
           !action.isEmpty {
            parts.append("On screen, the action you need to do is: \(action)")
            parts.append("As a result, you should see: \(scene.onScreen.result)")
        } else {
            parts.append("On screen, you should see: \(scene.onScreen.result)")
        }

        parts.append("And the narration is: \(scene.narration)")
        return parts.joined(separator: "\n")
    }
}
