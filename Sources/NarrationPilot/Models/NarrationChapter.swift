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

    func visualURL(for scene: NarrationScene) -> URL? {
        guard let visualID = scene.visualId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !visualID.isEmpty else {
            return nil
        }

        let linkedLearningPage = scene.links
            .compactMap { URL(string: $0.url) }
            .first { $0.path.contains("/learn/") }
        let baseURL = linkedLearningPage ?? URL(
            string: "https://www.100jsprojects.com/learn/\(projectSlug)"
        )
        guard let baseURL,
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.fragment = visualID
        return components.url
    }
}

struct NarrationScene: Codable, Equatable, Identifiable {
    let id: String
    let sceneNumber: Int
    let sceneType: NarrationSceneType
    let title: String
    let displayTitle: String
    let onScreen: NarrationOnScreen
    let narration: String
    let code: NarrationCode?
    let links: [NarrationLink]
    let visualId: String?
}

struct NarrationOnScreen: Codable, Equatable {
    let action: String?
    let result: String
}

enum NarrationSceneType: String, Codable, CaseIterable {
    case action
    case result
    case explanation

    var label: String {
        switch self {
        case .action: "Action"
        case .result: "Result Only"
        case .explanation: "Explanation"
        }
    }
}

struct NarrationCode: Codable, Equatable {
    let text: String
    let language: String
    let targetFile: String
    let action: NarrationCodeAction
}

enum NarrationCodeAction: String, Codable, CaseIterable {
    case create
    case replace
    case append
    case insert
}

struct NarrationLink: Codable, Equatable, Identifiable {
    let label: String
    let url: String

    var id: String { "\(label)|\(url)" }
}

enum NarrationChapterLoader {
    static let supportedSchemaVersion = 4
    static let readableSchemaVersions = [2, 3, 4]

    static func load(from url: URL) throws -> NarrationChapter {
        try decode(Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> NarrationChapter {
        let version = try schemaVersion(in: data)
        let chapter: NarrationChapter

        do {
            switch version {
            case 4:
                chapter = try JSONDecoder().decode(NarrationChapter.self, from: data)
            case 3:
                chapter = migrate(try JSONDecoder().decode(LegacyNarrationChapterV3.self, from: data))
            case 2:
                chapter = migrate(try JSONDecoder().decode(LegacyNarrationChapterV2.self, from: data))
            default:
                throw NarrationChapterError.unsupportedSchemaVersion(version)
            }
        } catch let error as NarrationChapterError {
            throw error
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
        guard ["draft", "approved"].contains(chapter.status) else {
            throw NarrationChapterError.invalidStatus(chapter.status)
        }
        guard !chapter.scenes.isEmpty else {
            throw NarrationChapterError.noScenes
        }

        var sceneIDs = Set<String>()
        for (index, scene) in chapter.scenes.enumerated() {
            let expectedNumber = index + 1
            guard scene.sceneNumber == expectedNumber else {
                throw NarrationChapterError.invalidSceneNumber(expected: expectedNumber, actual: scene.sceneNumber)
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
            guard !scene.onScreen.result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw NarrationChapterError.emptyOnScreenResult(scene.sceneNumber)
            }
            let narration = scene.narration.trimmingCharacters(in: .whitespacesAndNewlines)
            let containsResultTransition = narration.localizedCaseInsensitiveContains("as you can see")
            switch scene.sceneType {
            case .action:
                guard let action = scene.onScreen.action,
                      !action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw NarrationChapterError.missingActionForActionScene(scene.sceneNumber)
                }
                guard !containsResultTransition else {
                    throw NarrationChapterError.resultTransitionOutsideResultScene(scene.sceneNumber)
                }
            case .result:
                guard scene.onScreen.action == nil else {
                    throw NarrationChapterError.unexpectedAction(scene.sceneNumber, scene.sceneType)
                }
                guard narration.hasPrefix("As you can see") else {
                    throw NarrationChapterError.invalidResultNarration(scene.sceneNumber)
                }
                guard index > 0, chapter.scenes[index - 1].sceneType == .action else {
                    throw NarrationChapterError.resultMustFollowAction(scene.sceneNumber)
                }
                guard scene.code == nil else {
                    throw NarrationChapterError.codeOutsideActionScene(scene.sceneNumber)
                }
            case .explanation:
                guard scene.onScreen.action == nil else {
                    throw NarrationChapterError.unexpectedAction(scene.sceneNumber, scene.sceneType)
                }
                guard !containsResultTransition else {
                    throw NarrationChapterError.resultTransitionOutsideResultScene(scene.sceneNumber)
                }
                guard scene.code == nil else {
                    throw NarrationChapterError.codeOutsideActionScene(scene.sceneNumber)
                }
            }
            if let code = scene.code {
                guard !code.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      !code.language.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      !code.targetFile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw NarrationChapterError.invalidCode(scene.sceneNumber)
                }
            }
            for link in scene.links {
                guard !link.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      let url = URL(string: link.url),
                      ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
                    throw NarrationChapterError.invalidLink(scene.sceneNumber)
                }
            }
            if let visualID = scene.visualId {
                let trimmedVisualID = visualID.trimmingCharacters(in: .whitespacesAndNewlines)
                let validVisualID = trimmedVisualID.range(
                    of: #"^[a-z0-9]+(?:-[a-z0-9]+)*$"#,
                    options: .regularExpression
                ) != nil
                guard validVisualID else {
                    throw NarrationChapterError.invalidVisualID(scene.sceneNumber)
                }
            }
        }
    }

    private static func schemaVersion(in data: Data) throws -> Int {
        do {
            let object = try JSONSerialization.jsonObject(with: data)
            guard let dictionary = object as? [String: Any],
                  let version = dictionary["schemaVersion"] as? Int else {
                throw NarrationChapterError.invalidJSON("schemaVersion is missing or invalid.")
            }
            return version
        } catch let error as NarrationChapterError {
            throw error
        } catch {
            throw NarrationChapterError.invalidJSON(error.localizedDescription)
        }
    }

    private static func migrate(_ legacy: LegacyNarrationChapterV2) -> NarrationChapter {
        NarrationChapter(
            schemaVersion: supportedSchemaVersion,
            projectSlug: legacy.projectSlug,
            chapterNumber: legacy.chapterNumber,
            chapterTitle: legacy.chapterTitle,
            status: legacy.status,
            scenes: legacy.scenes.map { scene in
                let sceneType = inferredSceneType(narration: scene.narration)
                return NarrationScene(
                    id: scene.id,
                    sceneNumber: scene.sceneNumber,
                    sceneType: sceneType,
                    title: scene.title,
                    displayTitle: scene.displayTitle,
                    onScreen: NarrationOnScreen(
                        action: sceneType == .action ? scene.onScreen.action : nil,
                        result: scene.onScreen.result
                    ),
                    narration: scene.narration,
                    code: scene.code.map {
                        NarrationCode(text: $0, language: "text", targetFile: "Unspecified", action: .insert)
                    },
                    links: [],
                    visualId: nil
                )
            }
        )
    }

    private static func migrate(_ legacy: LegacyNarrationChapterV3) -> NarrationChapter {
        NarrationChapter(
            schemaVersion: supportedSchemaVersion,
            projectSlug: legacy.projectSlug,
            chapterNumber: legacy.chapterNumber,
            chapterTitle: legacy.chapterTitle,
            status: legacy.status,
            scenes: legacy.scenes.map { scene in
                let sceneType = inferredSceneType(narration: scene.narration)
                return NarrationScene(
                    id: scene.id,
                    sceneNumber: scene.sceneNumber,
                    sceneType: sceneType,
                    title: scene.title,
                    displayTitle: scene.displayTitle,
                    onScreen: NarrationOnScreen(
                        action: sceneType == .action ? scene.onScreen.action : nil,
                        result: scene.onScreen.result
                    ),
                    narration: scene.narration,
                    code: scene.code,
                    links: scene.links,
                    visualId: nil
                )
            }
        )
    }

    private static func inferredSceneType(narration: String) -> NarrationSceneType {
        narration.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("As you can see") ? .result : .action
    }
}

private struct LegacyNarrationChapterV3: Codable {
    let schemaVersion: Int
    let projectSlug: String
    let chapterNumber: Int
    let chapterTitle: String
    let status: String
    let scenes: [LegacyNarrationSceneV3]
}

private struct LegacyNarrationSceneV3: Codable {
    let id: String
    let sceneNumber: Int
    let title: String
    let displayTitle: String
    let onScreen: LegacyNarrationOnScreen
    let narration: String
    let code: NarrationCode?
    let links: [NarrationLink]
}

private struct LegacyNarrationOnScreen: Codable {
    let action: String
    let result: String
}

private struct LegacyNarrationChapterV2: Codable {
    let schemaVersion: Int
    let projectSlug: String
    let chapterNumber: Int
    let chapterTitle: String
    let status: String
    let scenes: [LegacyNarrationSceneV2]
}

private struct LegacyNarrationSceneV2: Codable {
    let id: String
    let sceneNumber: Int
    let title: String
    let displayTitle: String
    let onScreen: NarrationOnScreen
    let narration: String
    let code: String?
}

enum NarrationChapterError: LocalizedError, Equatable {
    case invalidJSON(String)
    case unsupportedSchemaVersion(Int)
    case missingProjectSlug
    case invalidChapterNumber
    case missingChapterTitle
    case invalidStatus(String)
    case noScenes
    case invalidSceneNumber(expected: Int, actual: Int)
    case missingSceneID(Int)
    case duplicateSceneID(String)
    case emptyNarration(Int)
    case missingDisplayTitle(Int)
    case emptyOnScreenResult(Int)
    case missingActionForActionScene(Int)
    case unexpectedAction(Int, NarrationSceneType)
    case invalidResultNarration(Int)
    case resultMustFollowAction(Int)
    case resultTransitionOutsideResultScene(Int)
    case codeOutsideActionScene(Int)
    case invalidCode(Int)
    case invalidLink(Int)
    case invalidVisualID(Int)

    var errorDescription: String? {
        switch self {
        case .invalidJSON(let message): "Invalid chapter JSON: \(message)"
        case .unsupportedSchemaVersion(let version):
            "Unsupported schema version \(version). Narration Pilot reads versions \(NarrationChapterLoader.readableSchemaVersions.map(String.init).joined(separator: ", "))."
        case .missingProjectSlug: "The chapter is missing projectSlug."
        case .invalidChapterNumber: "chapterNumber must be greater than zero."
        case .missingChapterTitle: "The chapter is missing chapterTitle."
        case .invalidStatus(let status): "Unsupported chapter status: \(status)."
        case .noScenes: "The chapter must contain at least one scene."
        case .invalidSceneNumber(let expected, let actual):
            "Scene numbers must be sequential. Expected \(expected), found \(actual)."
        case .missingSceneID(let sceneNumber): "Scene \(sceneNumber) is missing an id."
        case .duplicateSceneID(let id): "The scene id \(id) is used more than once."
        case .emptyNarration(let sceneNumber): "Scene \(sceneNumber) has empty narration."
        case .missingDisplayTitle(let sceneNumber): "Scene \(sceneNumber) is missing displayTitle."
        case .emptyOnScreenResult(let sceneNumber): "Scene \(sceneNumber) has an empty onScreen result."
        case .missingActionForActionScene(let sceneNumber): "Action scene \(sceneNumber) must include one onScreen action."
        case .unexpectedAction(let sceneNumber, let sceneType): "\(sceneType.label) scene \(sceneNumber) cannot include an onScreen action."
        case .invalidResultNarration(let sceneNumber): "Result scene \(sceneNumber) narration must begin with As you can see."
        case .resultMustFollowAction(let sceneNumber): "Result scene \(sceneNumber) must immediately follow an action scene."
        case .resultTransitionOutsideResultScene(let sceneNumber): "Scene \(sceneNumber) uses As you can see outside a result scene."
        case .codeOutsideActionScene(let sceneNumber): "Scene \(sceneNumber) contains code but is not an action scene."
        case .invalidCode(let sceneNumber): "Scene \(sceneNumber) has incomplete structured code."
        case .invalidLink(let sceneNumber): "Scene \(sceneNumber) has an invalid link."
        case .invalidVisualID(let sceneNumber): "Scene \(sceneNumber) has an invalid visualId. Use lowercase words separated by hyphens."
        }
    }
}
