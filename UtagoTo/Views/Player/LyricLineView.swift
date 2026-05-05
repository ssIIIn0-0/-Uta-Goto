import SwiftUI

struct LyricLineView: View {
    let tokens: [TokenWord]
    let translation: String?
    let isActive: Bool
    let showTranslation: Bool
    var onTokenTap: ((TokenWord) -> Void)?

    var body: some View {
        VStack(spacing: 4) {
            WrappingHStack(tokens: tokens, isActive: isActive, onTokenTap: onTokenTap)

            if showTranslation, let translation, !translation.isEmpty {
                Text(translation)
                    .font(.system(size: 14))
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            isActive ? Color.accentColor.opacity(0.08) : Color.clear,
            in: RoundedRectangle(cornerRadius: 8)
        )
        .opacity(isActive ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

struct WrappingHStack: View {
    let tokens: [TokenWord]
    let isActive: Bool
    var onTokenTap: ((TokenWord) -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tokens) { token in
                WordTokenView(token: token) {
                    onTokenTap?(token)
                }
                .font(.system(size: isActive ? 18 : 16))
            }
        }
    }
}
