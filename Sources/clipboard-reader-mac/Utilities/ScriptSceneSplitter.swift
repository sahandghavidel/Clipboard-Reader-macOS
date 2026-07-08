import Foundation

enum ScriptSceneSplitter {
    struct ScriptScene {
        let text: String
        let range: Range<String.Index>
    }

    static func scenes(from script: String) -> [String] {
        sceneRanges(from: script).map(\.text)
    }

    static func sceneRanges(from script: String) -> [ScriptScene] {
        let normalizedScript = normalized(script)

        var scenes: [ScriptScene] = []
        var sceneStart = normalizedScript.startIndex
        var index = normalizedScript.startIndex

        while index < normalizedScript.endIndex {
            let character = normalizedScript[index]
            let nextIndex = normalizedScript.index(after: index)

            if isSentenceTerminator(character),
               nextIndex == normalizedScript.endIndex || normalizedScript[nextIndex].isWhitespace {
                appendScene(in: normalizedScript, range: sceneStart..<nextIndex, to: &scenes)
                sceneStart = nextIndex
            }

            index = nextIndex
        }

        appendScene(in: normalizedScript, range: sceneStart..<normalizedScript.endIndex, to: &scenes)
        return scenes
    }

    static func normalized(_ script: String) -> String {
        script
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    private static func isSentenceTerminator(_ character: Character) -> Bool {
        character == "." || character == "!" || character == "?" || character == "…"
    }

    private static func appendScene(in script: String, range: Range<String.Index>, to scenes: inout [ScriptScene]) {
        var lowerBound = range.lowerBound
        var upperBound = range.upperBound

        while lowerBound < upperBound, script[lowerBound].isWhitespace {
            lowerBound = script.index(after: lowerBound)
        }

        while lowerBound < upperBound {
            let previousIndex = script.index(before: upperBound)
            guard script[previousIndex].isWhitespace else {
                break
            }
            upperBound = previousIndex
        }

        guard lowerBound < upperBound else {
            return
        }

        let trimmedRange = lowerBound..<upperBound
        let scene = script[trimmedRange]
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if !scene.isEmpty {
            scenes.append(ScriptScene(text: scene, range: trimmedRange))
        }
    }
}
