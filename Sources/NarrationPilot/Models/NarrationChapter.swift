import Foundation

enum ScriptInputFormat: String, CaseIterable, Identifiable {
    case text
    case json

    var id: String { rawValue }

    var label: String {
        switch self {
        case .text: "Text Script"
        case .json: "Chapter JSON"
        }
    }
}

struct NarrationChapter: Codable, Equatable {
    let schemaVersion: Int
    let projectSlug: String
    let chapterNumber: Int
    let chapterTitle: String
    let status: String
    let scenes: [NarrationScene]
}

struct NarrationScene: Codable, Equatable, Identifiable {
    let id: String
    let sceneNumber: Int
    let title: String
    let displayTitle: String
    let onScreen: NarrationOnScreen
    let narration: String
    let code: String?
}

struct NarrationOnScreen: Codable, Equatable {
    let action: String
    let result: String
}

enum NarrationChapterLoader {
    static let supportedSchemaVersion = 2

    static func load(from url: URL) throws -> NarrationChapter {
        try decode(Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> NarrationChapter {
        let chapter: NarrationChapter
        do {
            chapter = try JSONDecoder().decode(NarrationChapter.self, from: data)
        } catch {
            throw NarrationChapterError.invalidJSON(error.localizedDescription)
        }

        try validate(chapter)
        return chapter
    }

    static func validate(_ chapter: NarrationChapter) throws {
        guard chapter.schemaVersion == supportedSchemaVersion else {
            throw NarrationChapterError.unsupportedSchemaVersion(chapter.schemaVersion)
        }
        guard !chapter.projectSlug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NarrationChapterError.missingProjectSlug
        }
        guard chapter.chapterNumber > 0 else {
            throw NarrationChapterError.invalidChapterNumber
        }
        guard !chapter.chapterTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NarrationChapterError.missingChapterTitle
        }
        guard !chapter.scenes.isEmpty else {
            throw NarrationChapterError.noScenes
        }

        var sceneIDs = Set<String>()
        for (index, scene) in chapter.scenes.enumerated() {
            let expectedNumber = index + 1
            guard scene.sceneNumber == expectedNumber else {
                throw NarrationChapterError.invalidSceneNumber(
                    expected: expectedNumber,
                    actual: scene.sceneNumber
                )
            }
            let trimmedID = scene.id.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedID.isEmpty else {
                throw NarrationChapterError.missingSceneID(scene.sceneNumber)
            }
            guard sceneIDs.insert(trimmedID).inserted else {
                throw NarrationChapterError.duplicateSceneID(trimmedID)
            }
            guard !scene.narration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw NarrationChapterError.emptyNarration(scene.sceneNumber)
            }
            guard !scene.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw NarrationChapterError.missingDisplayTitle(scene.sceneNumber)
            }
            guard !scene.onScreen.action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw NarrationChapterError.emptyOnScreenAction(scene.sceneNumber)
            }
            guard !scene.onScreen.result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw NarrationChapterError.emptyOnScreenResult(scene.sceneNumber)
            }
        }
    }
}

enum NarrationChapterError: LocalizedError, Equatable {
    case invalidJSON(String)
    case unsupportedSchemaVersion(Int)
    case missingProjectSlug
    case invalidChapterNumber
    case missingChapterTitle
    case noScenes
    case invalidSceneNumber(expected: Int, actual: Int)
    case missingSceneID(Int)
    case duplicateSceneID(String)
    case emptyNarration(Int)
    case missingDisplayTitle(Int)
    case emptyOnScreenAction(Int)
    case emptyOnScreenResult(Int)

    var errorDescription: String? {
        switch self {
        case .invalidJSON(let message):
            "Invalid chapter JSON: \(message)"
        case .unsupportedSchemaVersion(let version):
            "Unsupported schema version \(version). Narration Pilot supports version \(NarrationChapterLoader.supportedSchemaVersion)."
        case .missingProjectSlug:
            "The chapter is missing projectSlug."
        case .invalidChapterNumber:
            "chapterNumber must be greater than zero."
        case .missingChapterTitle:
            "The chapter is missing chapterTitle."
        case .noScenes:
            "The chapter must contain at least one scene."
        case .invalidSceneNumber(let expected, let actual):
            "Scene numbers must be sequential. Expected \(expected), found \(actual)."
        case .missingSceneID(let sceneNumber):
            "Scene \(sceneNumber) is missing an id."
        case .duplicateSceneID(let id):
            "The scene id \(id) is used more than once."
        case .emptyNarration(let sceneNumber):
            "Scene \(sceneNumber) has empty narration."
        case .missingDisplayTitle(let sceneNumber):
            "Scene \(sceneNumber) is missing displayTitle."
        case .emptyOnScreenAction(let sceneNumber):
            "Scene \(sceneNumber) has an empty onScreen action."
        case .emptyOnScreenResult(let sceneNumber):
            "Scene \(sceneNumber) has an empty onScreen result."
        }
    }
}
