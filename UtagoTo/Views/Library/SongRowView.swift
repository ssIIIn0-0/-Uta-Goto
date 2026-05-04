import SwiftUI

struct SongRowView: View {
    let song: Song
    let distribution: [JLPTLevel: Int]

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            distributionBar
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(song.title), \(song.artist)")
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let data = song.thumbnailData,
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "music.note")
                        .foregroundStyle(.secondary)
                }
        }
    }

    @ViewBuilder
    private var distributionBar: some View {
        let total = distribution.values.reduce(0, +)
        if total > 0 {
            HStack(spacing: 1) {
                ForEach([JLPTLevel.n5, .n4, .n3, .n2, .n1], id: \.self) { level in
                    let count = distribution[level] ?? 0
                    if count > 0 {
                        let fraction = CGFloat(count) / CGFloat(total)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(level.color)
                            .frame(width: max(4, fraction * 60), height: 16)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .accessibilityLabel("JLPT 분포")
        }
    }
}
