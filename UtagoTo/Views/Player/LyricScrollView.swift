import SwiftUI

struct LyricScrollView: View {
    let lines: [LyricLine]
    let tokenizedLines: [[TokenWord]]
    let activeLineIndex: Int
    let showTranslation: Bool
    var onTokenTap: ((TokenWord, Int) -> Void)?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        let tokens = index < tokenizedLines.count ? tokenizedLines[index] : []
                        LyricLineView(
                            tokens: tokens,
                            translation: line.translationText,
                            isActive: index == activeLineIndex,
                            showTranslation: showTranslation
                        ) { token in
                            onTokenTap?(token, index)
                        }
                        .id(index)
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: activeLineIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.35)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }
}
