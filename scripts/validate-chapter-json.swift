import Foundation

@main
struct ValidateChapterJSON {
    static func main() {
        guard CommandLine.arguments.count == 2 else {
            FileHandle.standardError.write(Data("Usage: validate-chapter-json <chapter.json>\n".utf8))
            exit(64)
        }

        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        do {
            let chapter = try NarrationChapterLoader.load(from: url)
            print("Valid chapter: \(chapter.chapterTitle) (\(chapter.scenes.count) scenes)")
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            FileHandle.standardError.write(Data("Invalid chapter: \(message)\n".utf8))
            exit(1)
        }
    }
}
