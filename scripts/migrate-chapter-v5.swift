import Foundation

@main
struct MigrateChapterV5 {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            FileHandle.standardError.write(Data("Usage: migrate-chapter-v5 <chapter.json>\n".utf8))
            Foundation.exit(2)
        }

        let url = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        let originalData = try Data(contentsOf: url)
        let chapter = try NarrationChapterLoader.decode(originalData)
        let migratedData = try JSONEncoder.narrationPilot.encode(chapter)
        let backupURL = url.appendingPathExtension("v4.backup")

        if !FileManager.default.fileExists(atPath: backupURL.path) {
            try originalData.write(to: backupURL, options: .atomic)
        }
        try migratedData.write(to: url, options: .atomic)
        print("Migrated \(chapter.scenes.count) scenes to schema version \(chapter.schemaVersion).")
        print("Backup: \(backupURL.path)")
    }
}
