import Foundation
import SwiftData
import SwiftUI

@Observable
final class VocabViewModel {
    var entries: [VocabEntry] = []
    var searchText: String = ""
    var selectedLevel: JLPTLevel?
    var sortOption: SortOption = .addedDate
    var errorMessage: String?

    private var modelContext: ModelContext?
    private let dictionary = JLPTDictionaryService.shared

    enum SortOption: String, CaseIterable {
        case addedDate = "추가순"
        case alphabetical = "가나다순"
        case encounterCount = "등장횟수"
        case jlptLevel = "JLPT 레벨"
    }

    func setup(context: ModelContext) {
        self.modelContext = context
        fetchEntries()
    }

    func fetchEntries() {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<VocabEntry>(sortBy: [SortDescriptor(\.addedAt, order: .reverse)])
            entries = try context.fetch(descriptor)
        } catch {
            errorMessage = "단어장을 불러올 수 없습니다."
        }
    }

    var filteredEntries: [VocabEntry] {
        var result = entries

        if let level = selectedLevel {
            result = result.filter { $0.jlptLevel == level }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.word.lowercased().contains(query) ||
                $0.reading.lowercased().contains(query) ||
                $0.meaning.lowercased().contains(query)
            }
        }

        switch sortOption {
        case .addedDate:
            result.sort { $0.addedAt > $1.addedAt }
        case .alphabetical:
            result.sort { $0.reading < $1.reading }
        case .encounterCount:
            result.sort { $0.reviewCount > $1.reviewCount }
        case .jlptLevel:
            result.sort { $0.jlptLevel < $1.jlptLevel }
        }

        return result
    }

    func recordEncounter(token: TokenWord, in song: Song, lineText: String, lineIndex: Int) {
        guard let context = modelContext else { return }

        let wordStr = token.surface
        let descriptor = FetchDescriptor<VocabEntry>(predicate: #Predicate { $0.word == wordStr })

        do {
            let existing = try context.fetch(descriptor)

            let vocabEntry: VocabEntry
            if let found = existing.first {
                found.reviewCount += 1
                found.lastReviewedAt = Date()
                vocabEntry = found
            } else {
                let dictEntry = dictionary.entry(for: token.surface)
                vocabEntry = VocabEntry(
                    word: token.surface,
                    reading: dictEntry?.reading ?? token.reading,
                    meaning: dictEntry?.meaning ?? "",
                    partOfSpeech: dictEntry?.partOfSpeech ?? "",
                    jlptLevel: token.jlptLevel,
                    reviewCount: 1
                )
                context.insert(vocabEntry)
            }

            let songId = song.id
            let existingAppearances = vocabEntry.appearances.filter {
                $0.song?.id == songId && $0.lyricLineIndex == lineIndex
            }

            if existingAppearances.isEmpty {
                let appearance = WordAppearance(
                    vocabEntry: vocabEntry,
                    song: song,
                    lyricLineText: lineText,
                    lyricLineIndex: lineIndex
                )
                context.insert(appearance)
                vocabEntry.appearances.append(appearance)
                song.wordAppearances.append(appearance)
            }

            try context.save()
            fetchEntries()
        } catch {
            errorMessage = "저장에 실패했습니다."
        }
    }

    func isWordSaved(_ surface: String) -> Bool {
        entries.contains { $0.word == surface }
    }

    func toggleFavorite(_ entry: VocabEntry) {
        entry.isFavorite.toggle()
        save()
    }

    func deleteEntry(_ entry: VocabEntry) {
        guard let context = modelContext else { return }
        context.delete(entry)
        save()
        fetchEntries()
    }

    private func save() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            errorMessage = "저장에 실패했습니다."
        }
    }
}
