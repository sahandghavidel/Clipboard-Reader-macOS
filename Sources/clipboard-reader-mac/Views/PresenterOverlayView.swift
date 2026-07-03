import SwiftUI

struct PresenterOverlayView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            sceneColumn(title: "Previous", text: appModel.previousSceneText, isCurrent: false)

            VStack(alignment: .leading, spacing: 6) {
                Text(appModel.scriptSceneProgress)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.72))

                Text(appModel.currentSceneText ?? "Paste a script and turn on Script mode.")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)

            sceneColumn(title: "Next", text: appModel.nextSceneText, isCurrent: false)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.black.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.white.opacity(0.16))
        )
    }

    private func sceneColumn(title: String, text: String?, isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.48))

            Text(text ?? "None")
                .font(.system(size: isCurrent ? 20 : 13, weight: isCurrent ? .semibold : .regular))
                .foregroundStyle(.white.opacity(text == nil ? 0.32 : 0.68))
                .lineLimit(4)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 210)
    }
}
