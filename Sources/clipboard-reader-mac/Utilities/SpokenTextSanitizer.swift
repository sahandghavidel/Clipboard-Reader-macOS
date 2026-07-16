import Foundation

enum SpokenTextSanitizer {
    static func preparingForSpeech(_ text: String, includesBracketedDirections: Bool) -> String {
        if includesBracketedDirections {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return removingBracketedDirections(from: text)
    }

    static func removingBracketedDirections(from text: String) -> String {
        var spokenText = ""
        var bracketedText = ""
        var bracketDepth = 0

        for character in text {
            if character == "[" {
                if bracketDepth == 0 {
                    bracketedText = ""
                }

                bracketDepth += 1
                bracketedText.append(character)
                continue
            }

            if bracketDepth > 0 {
                bracketedText.append(character)

                if character == "]" {
                    bracketDepth -= 1
                    if bracketDepth == 0 {
                        bracketedText = ""
                        spokenText.append(" ")
                    }
                }

                continue
            }

            spokenText.append(character)
        }

        // Keep incomplete bracketed text because it may be intended narration.
        if bracketDepth > 0 {
            spokenText.append(bracketedText)
        }

        return spokenText
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
