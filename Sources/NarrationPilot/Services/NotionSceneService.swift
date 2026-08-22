import Foundation
import Security

struct NotionSceneRecord: Equatable {
    let pageID: String
    let lastEditedTime: String
    let scene: NarrationScene
}

enum NotionSceneError: LocalizedError {
    case invalidResponse
    case api(String)
    case invalidScenes(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Notion returned an invalid response."
        case .api(let message): message
        case .invalidScenes(let message): message
        }
    }
}

@MainActor
final class NotionSceneService {
    static let apiVersion = "2026-03-11"

    func fetchScenes(token: String, dataSourceID: String) async throws -> [NotionSceneRecord] {
        var records: [NotionSceneRecord] = []
        var cursor: String?

        repeat {
            var body: [String: Any] = ["page_size": 100]
            if let cursor { body["start_cursor"] = cursor }
            let result = try await request(
                path: "/v1/data_sources/\(cleanID(dataSourceID))/query",
                method: "POST",
                token: token,
                body: body
            )
            guard let pages = result["results"] as? [[String: Any]] else {
                throw NotionSceneError.invalidResponse
            }
            records.append(contentsOf: try pages.compactMap(record(from:)))
            cursor = (result["has_more"] as? Bool) == true ? result["next_cursor"] as? String : nil
        } while cursor != nil

        return records.sorted { $0.scene.sceneNumber < $1.scene.sceneNumber }
    }

    func updateScene(_ scene: NarrationScene, pageID: String, token: String) async throws {
        let code = scene.code
        let properties: [String: Any] = [
            "Scene Number": titleText(String(scene.sceneNumber)),
            "Narration": richText(scene.narration),
            "On Screen": richText(scene.onScreen),
            "Annotation": richText(scene.annotation ?? ""),
            "Code": richText(code?.text ?? ""),
            "Language": richText(code?.language ?? ""),
            "Target File": richText(code?.targetFile ?? ""),
            "Code Instruction": richText(code?.instruction ?? "")
        ]
        _ = try await request(
            path: "/v1/pages/\(cleanID(pageID))",
            method: "PATCH",
            token: token,
            body: ["properties": properties]
        )
    }

    static func isBlankScene(narration: String, onScreen: String) -> Bool {
        narration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && onScreen.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func record(from page: [String: Any]) throws -> NotionSceneRecord? {
        guard let pageID = page["id"] as? String,
              let properties = page["properties"] as? [String: Any] else {
            throw NotionSceneError.invalidResponse
        }

        let narration = text(properties["Narration"])
        let onScreen = text(properties["On Screen"])
        if Self.isBlankScene(narration: narration, onScreen: onScreen) {
            return nil
        }

        guard
              let sceneNumber = Int(text(properties["Scene Number"]).trimmingCharacters(in: .whitespacesAndNewlines)),
              sceneNumber > 0 else {
            throw NotionSceneError.invalidScenes("A Notion row is missing a valid Scene Number.")
        }

        let codeText = text(properties["Code"])
        let code: NarrationCode?
        if codeText.isEmpty {
            code = nil
        } else {
            let language = text(properties["Language"])
            let targetFile = text(properties["Target File"])
            let instruction = text(properties["Code Instruction"])
            let action = inferredAction(from: instruction)
            guard !language.isEmpty, !targetFile.isEmpty else {
                throw NotionSceneError.invalidScenes("Scene \(sceneNumber) code needs Language and Target File values.")
            }
            code = NarrationCode(
                text: codeText,
                language: language,
                targetFile: targetFile,
                action: action,
                instruction: instruction.isEmpty ? nil : instruction
            )
        }
        guard !narration.isEmpty, !onScreen.isEmpty else {
            throw NotionSceneError.invalidScenes("Scene \(sceneNumber) needs Narration and On Screen values.")
        }

        return NotionSceneRecord(
            pageID: pageID,
            lastEditedTime: lastEdited(properties["Last Edited"]) ?? (page["last_edited_time"] as? String ?? ""),
            scene: NarrationScene(
                id: "scene-\(sceneNumber)",
                sceneNumber: sceneNumber,
                narration: narration,
                onScreen: onScreen,
                code: code,
                annotation: nilIfEmpty(text(properties["Annotation"]))
            )
        )
    }

    private func request(path: String, method: String, token: String, body: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: "https://api.notion.com\(path)") else { throw NotionSceneError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NotionSceneError.invalidResponse }
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        guard (200..<300).contains(http.statusCode) else {
            let message = object["message"] as? String ?? "Notion request failed (\(http.statusCode))."
            throw NotionSceneError.api(message)
        }
        return object
    }

    private func richText(_ value: String) -> [String: Any] {
        ["rich_text": value.isEmpty ? [] : [["type": "text", "text": ["content": value]]]]
    }

    private func titleText(_ value: String) -> [String: Any] {
        ["title": [["type": "text", "text": ["content": value]]]]
    }

    private func text(_ property: Any?) -> String {
        guard let property = property as? [String: Any] else { return "" }
        let values = (property["title"] as? [[String: Any]]) ?? (property["rich_text"] as? [[String: Any]]) ?? []
        return values.compactMap { $0["plain_text"] as? String }.joined()
    }

    private func lastEdited(_ property: Any?) -> String? {
        (property as? [String: Any])?["last_edited_time"] as? String
    }

    private func inferredAction(from instruction: String) -> NarrationCodeAction {
        let value = instruction.lowercased()
        if value.hasPrefix("replace") { return .replace }
        if value.hasPrefix("append") { return .append }
        if value.hasPrefix("create") { return .create }
        return .insert
    }

    private func nilIfEmpty(_ value: String) -> String? { value.isEmpty ? nil : value }
    private func cleanID(_ value: String) -> String { value.trimmingCharacters(in: .whitespacesAndNewlines) }
}

enum NotionTokenStore {
    private static let service = "local.clipboardreadermac.notion"
    private static let account = "integration-token"

    static func load() -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func save(_ token: String) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(base as CFDictionary)
        guard !token.isEmpty else { return }
        var item = base
        item[kSecValueData as String] = Data(token.utf8)
        SecItemAdd(item as CFDictionary, nil)
    }
}
