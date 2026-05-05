import SwiftUI

struct VocabCardView: View {
    let entry: VocabEntry

    private let pronunciation = JapanesePronunciationService.shared

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(entry.jlptLevel.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    JLPTBadgeView(level: entry.jlptLevel)

                    Text(entry.word)
                        .font(.title3.bold())

                    Text(entry.reading)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(pronunciation.toKorean(entry.reading))
                        .font(.caption)
                        .foregroundStyle(.orange)

                    Spacer()

                    if entry.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }

                HStack(spacing: 4) {
                    Text(entry.meaning)
                    if !entry.partOfSpeech.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(entry.partOfSpeech)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)

                if !entry.songContextSummary.isEmpty {
                    Divider()

                    HStack(spacing: 8) {
                        Label(entry.songContextSummary, systemImage: "music.note")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(entry.reviewCount)번 만남")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.word), \(entry.reading), \(entry.meaning), JLPT \(entry.jlptLevel.displayName)")
    }
}
