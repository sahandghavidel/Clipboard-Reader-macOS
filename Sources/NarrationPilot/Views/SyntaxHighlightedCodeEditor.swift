import AppKit
import SwiftUI

struct SyntaxHighlightedCodeEditor: NSViewRepresentable {
    @Binding var text: String
    let language: String
    var isEditable = true

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.backgroundColor = NSColor(calibratedRed: 0.98, green: 0.98, blue: 0.97, alpha: 1)
        textView.textColor = NSColor(calibratedWhite: 0.16, alpha: 1)
        textView.string = text
        context.coordinator.highlight(textView)

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        context.coordinator.parent = self
        textView.isEditable = isEditable
        if textView.string != text {
            textView.string = text
        }
        context.coordinator.highlight(textView)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SyntaxHighlightedCodeEditor
        private var isHighlighting = false

        init(parent: SyntaxHighlightedCodeEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard !isHighlighting, let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            highlight(textView)
        }

        func highlight(_ textView: NSTextView) {
            guard !isHighlighting, let storage = textView.textStorage else { return }
            isHighlighting = true
            let selection = textView.selectedRanges
            let fullRange = NSRange(location: 0, length: storage.length)
            storage.beginEditing()
            storage.setAttributes([
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                .foregroundColor: NSColor(calibratedWhite: 0.16, alpha: 1)
            ], range: fullRange)

            let language = parent.language.lowercased()
            if language.contains("html") {
                apply(#"</?[A-Za-z][^>]*>"#, color: color(0.00, 0.36, 0.72), to: storage)
                apply(#"\b[A-Za-z-]+(?=\s*=)"#, color: color(0.45, 0.18, 0.55), to: storage)
            } else if language.contains("css") {
                apply(#"(^|[}\s])([.#]?[A-Za-z][A-Za-z0-9_-]*)(?=\s*\{)"#, color: color(0.72, 0.29, 0.00), to: storage)
                apply(#"\b[a-z-]+(?=\s*:)"#, color: color(0.00, 0.36, 0.72), to: storage)
            } else {
                apply(#"\b(const|let|var|function|return|if|else|for|while|class|new|async|await|import|from|export|try|catch|throw|true|false|null|undefined)\b"#, color: color(0.45, 0.18, 0.55), to: storage)
                apply(#"\b[A-Za-z_$][A-Za-z0-9_$]*(?=\s*\()"#, color: color(0.48, 0.35, 0.00), to: storage)
            }
            apply(#"(['\"])(?:\\.|(?!\1).)*\1"#, color: color(0.05, 0.48, 0.20), to: storage)
            apply(#"\b\d+(?:\.\d+)?\b"#, color: color(0.05, 0.42, 0.42), to: storage)
            apply(#"//.*|/\*[\s\S]*?\*/|<!--([\s\S]*?)-->"#, color: color(0.32, 0.49, 0.35), to: storage)
            storage.endEditing()
            textView.selectedRanges = selection
            isHighlighting = false
        }

        private func apply(_ pattern: String, color: NSColor, to storage: NSTextStorage) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return }
            let range = NSRange(location: 0, length: storage.length)
            for match in regex.matches(in: storage.string, range: range) {
                storage.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        }

        private func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> NSColor {
            NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1)
        }
    }
}
