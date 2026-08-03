import Foundation

@MainActor
final class ChapterFileWatcher {
    private struct Signature: Equatable {
        let modificationDate: Date
        let size: UInt64
    }

    private var watchTask: Task<Void, Never>?

    func start(url: URL, onChange: @escaping @MainActor (URL) -> Void) {
        stop()
        var previousSignature = signature(for: url)

        watchTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(750))
                guard !Task.isCancelled else { return }

                let currentSignature = signature(for: url)
                guard let currentSignature, currentSignature != previousSignature else {
                    continue
                }

                previousSignature = currentSignature
                onChange(url)
            }
        }
    }

    func stop() {
        watchTask?.cancel()
        watchTask = nil
    }

    private func signature(for url: URL) -> Signature? {
        guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
              let modificationDate = values.contentModificationDate,
              let fileSize = values.fileSize else {
            return nil
        }

        return Signature(modificationDate: modificationDate, size: UInt64(fileSize))
    }
}
