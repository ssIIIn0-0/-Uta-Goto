import SwiftUI

struct WordTokenView: View {
    let token: TokenWord
    var onTap: (() -> Void)?

    @State private var isPressed = false

    var body: some View {
        if token.isJapanese {
            Text(token.surface)
                .font(.system(size: 17))
                .foregroundStyle(token.jlptLevel.color)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    token.jlptLevel.color.opacity(isPressed ? 0.4 : 0.15),
                    in: RoundedRectangle(cornerRadius: 4)
                )
                .scaleEffect(isPressed ? 1.15 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isPressed)
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()

                    isPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isPressed = false
                    }
                    onTap?()
                }
                .accessibilityLabel("\(token.surface), JLPT \(token.jlptLevel.displayName)")
                .accessibilityHint("탭하여 단어 정보 보기")
        } else {
            Text(token.surface)
                .font(.system(size: 17))
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    HStack {
        WordTokenView(token: TokenWord(surface: "夢", reading: "ゆめ", jlptLevel: .n3, isJapanese: true))
        WordTokenView(token: TokenWord(surface: "なら", reading: "なら", jlptLevel: .n4, isJapanese: true))
        WordTokenView(token: TokenWord(surface: "ば", reading: "ば", jlptLevel: .unknown, isJapanese: false))
    }
    .padding()
}
