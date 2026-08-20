import Foundation

enum JSONSceneReplayFormatter {
    static func spokenParts(for scene: NarrationScene) -> [String] {
        [scene.narration, "On screen: \(scene.onScreen)"]
    }

    static func spokenText(for scene: NarrationScene) -> String {
        spokenParts(for: scene).joined(separator: "\n")
    }
}
