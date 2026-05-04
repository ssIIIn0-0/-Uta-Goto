import SwiftUI

struct WordDetailView: View {
    let entry: VocabEntry
    @Bindable var vocabVM: VocabViewModel
    var onNavigateToSong: ((Song) -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                meaningSection
                if !entry.appearances.isEmpty {
                    appearancesSection
                }
            }
            .padding()
        }
        .navigationTitle(entry.word)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    vocabVM.toggleFavorite(entry)
                } label: {
                    Image(systemName: entry.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(entry.isFavorite ? .yellow : .secondary)
                }
                .accessibilityLabel(entry.isFavorite ? "즐겨찾기 해제" : "즐겨찾기")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            JLPTBadgeView(level: entry.jlptLevel)

            Text(entry.word)
                .font(.system(size: 48, weight: .bold))

            Text(entry.reading)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var meaningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(entry.meaning)
                    .font(.title3)
                if !entry.partOfSpeech.isEmpty {
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(entry.partOfSpeech)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 16) {
                Label("\(entry.reviewCount)번 만남", systemImage: "eye")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let date = entry.lastReviewedAt {
                    Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "clock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var appearancesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("등장한 노래")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(groupedAppearances, id: \.song.id) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "music.note")
                            .foregroundStyle(.secondary)
                        Text(item.song.title)
                            .font(.subheadline.bold())
                        Text("· \(item.song.artist)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(item.lines, id: \.self) { lineText in
                        Text("「\(lineText)」")
                            .font(.body)
                            .italic()
                            .foregroundStyle(.primary.opacity(0.8))
                    }

                    HStack {
                        if let first = item.firstEncounter {
                            Text(first.formatted(date: .abbreviated, time: .omitted) + " 처음 만남")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Button {
                            onNavigateToSong?(item.song)
                        } label: {
                            Label("노래 열기", systemImage: "play.fill")
                                .font(.caption)
                        }
                        .accessibilityLabel("\(item.song.title) 재생")
                    }

                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private struct SongAppearanceGroup {
        let song: Song
        let lines: [String]
        let firstEncounter: Date?
    }

    private var groupedAppearances: [SongAppearanceGroup] {
        var groups: [UUID: SongAppearanceGroup] = [:]

        for appearance in entry.appearances {
            guard let song = appearance.song else { continue }
            if var existing = groups[song.id] {
                var lines = existing.lines
                if !lines.contains(appearance.lyricLineText) {
                    lines.append(appearance.lyricLineText)
                }
                let earliest = [existing.firstEncounter, appearance.encounteredAt].compactMap { $0 }.min()
                groups[song.id] = SongAppearanceGroup(song: song, lines: lines, firstEncounter: earliest)
            } else {
                groups[song.id] = SongAppearanceGroup(
                    song: song,
                    lines: [appearance.lyricLineText],
                    firstEncounter: appearance.encounteredAt
                )
            }
        }

        return Array(groups.values).sorted { ($0.firstEncounter ?? .distantPast) < ($1.firstEncounter ?? .distantPast) }
    }
}
