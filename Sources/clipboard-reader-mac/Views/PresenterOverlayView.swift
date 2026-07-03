import SwiftUI

struct PresenterOverlayView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            sceneColumn(title: "Previous", text: appModel.previousSceneText, isCurrent: false)

            VStack(alignment: .leading, spacing: 6) {
                Text(appModel.scriptSceneProgress)
                    .font(.caption.bold())
                    .foregroundStyle(appModel.presenterOverlaySecondaryTextColor.opacity(0.72))

                Text(appModel.currentSceneText ?? "Paste a script and turn on Script mode.")
                    .font(.system(size: CGFloat(appModel.presenterOverlayCurrentFontSize), weight: .semibold))
                    .foregroundStyle(appModel.presenterOverlayCurrentTextColor)
                    .lineLimit(nil)
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
                .fill(.black.opacity(appModel.presenterOverlayOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(appModel.presenterOverlayCurrentTextColor.opacity(0.16))
        )
    }

    private func sceneColumn(title: String, text: String?, isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(appModel.presenterOverlaySecondaryTextColor.opacity(0.48))

            Text(text ?? "None")
                .font(.system(size: CGFloat(appModel.presenterOverlaySideFontSize)))
                .foregroundStyle(appModel.presenterOverlaySecondaryTextColor.opacity(text == nil ? 0.32 : 0.68))
                .lineLimit(nil)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: CGFloat(appModel.presenterOverlaySideColumnWidth))
    }
}
