import AppKit
import Foundation

struct ClipboardService {
    func currentText() -> String? {
        guard let raw = NSPasteboard.general.string(forType: .string) else {
            return nil
        }

        let normalized = normalize(raw)
        return normalized.isEmpty ? nil : normalized
    }

    func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}