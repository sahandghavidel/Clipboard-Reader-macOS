import Foundation

enum ScriptSceneSplitter {
    static func scenes(from script: String) -> [String] {
        let normalizedScript = script
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        var scenes: [String] = []
        var current = ""
        let characters = Array(normalizedScript)

        for index in characters.indices {
            let character = characters[index]
            current.append(character)

            if isSentenceTerminator(character) {
                let nextIndex = characters.index(after: index)
                if nextIndex == characters.endIndex || characters[nextIndex].isWhitespace {
                    appendScene(current, to: &scenes)
                    current = ""
                }
            }
        }

        appendScene(current, to: &scenes)
        return scenes
    }

    private static func isSentenceTerminator(_ character: Character) -> Bool {
        character == "." || character == "!" || character == "?" || character == "…"
    }

    private static func appendScene(_ rawScene: String, to scenes: inout [String]) {
        let scene = rawScene
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if !scene.isEmpty {
            scenes.append(scene)
        }
    }
}
