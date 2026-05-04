import Foundation
import NaturalLanguage

struct TokenWord: Identifiable {
    let id = UUID()
    let surface: String
    let reading: String
    let jlptLevel: JLPTLevel
    let isJapanese: Bool
}

final class LyricParserService {
    static let shared = LyricParserService()

    private let dictionary = JLPTDictionaryService.shared

    private init() {}

    func tokenize(line: String) -> [TokenWord] {
        guard !line.isEmpty else { return [] }

        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = line

        var tokens: [TokenWord] = []
        var lastEnd = line.startIndex

        tokenizer.enumerateTokens(in: line.startIndex..<line.endIndex) { range, _ in
            if lastEnd < range.lowerBound {
                let gap = String(line[lastEnd..<range.lowerBound])
                if !gap.trimmingCharacters(in: .whitespaces).isEmpty {
                    tokens.append(TokenWord(
                        surface: gap,
                        reading: gap,
                        jlptLevel: .unknown,
                        isJapanese: false
                    ))
                }
            }

            let surface = String(line[range])
            let isJP = Self.isJapaneseWord(surface)

            let reading: String
            let level: JLPTLevel

            if isJP {
                reading = Self.hiraganaReading(for: surface) ?? surface
                let dictEntry = dictionary.entry(for: surface)
                level = dictEntry?.jlptLevel ?? dictionary.level(for: surface)
            } else {
                reading = surface
                level = .unknown
            }

            tokens.append(TokenWord(
                surface: surface,
                reading: reading,
                jlptLevel: level,
                isJapanese: isJP
            ))

            lastEnd = range.upperBound
            return true
        }

        if lastEnd < line.endIndex {
            let remaining = String(line[lastEnd..<line.endIndex])
            if !remaining.trimmingCharacters(in: .whitespaces).isEmpty {
                tokens.append(TokenWord(
                    surface: remaining,
                    reading: remaining,
                    jlptLevel: .unknown,
                    isJapanese: false
                ))
            }
        }

        return tokens
    }

    func parseLRC(content: String) -> [(timestamp: Double, text: String)] {
        let pattern = #"\[(\d{2}):(\d{2}\.\d{2,3})\](.+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        var results: [(timestamp: Double, text: String)] = []

        for line in content.components(separatedBy: .newlines) {
            let nsLine = line as NSString
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))

            for match in matches {
                guard match.numberOfRanges >= 4 else { continue }
                let minutes = Double(nsLine.substring(with: match.range(at: 1))) ?? 0
                let seconds = Double(nsLine.substring(with: match.range(at: 2))) ?? 0
                let text = nsLine.substring(with: match.range(at: 3))
                    .trimmingCharacters(in: .whitespaces)

                let timestamp = minutes * 60.0 + seconds
                results.append((timestamp: timestamp, text: text))
            }
        }

        return results.sorted { $0.timestamp < $1.timestamp }
    }

    private static func isJapaneseWord(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if (0x3040...0x309F).contains(scalar.value) ||  // Hiragana
               (0x30A0...0x30FF).contains(scalar.value) ||  // Katakana
               (0x4E00...0x9FFF).contains(scalar.value) ||  // CJK Unified
               (0x3400...0x4DBF).contains(scalar.value) {   // CJK Extension A
                return true
            }
        }
        return false
    }

    private static func hiraganaReading(for text: String) -> String? {
        let mutableString = NSMutableString(string: text)
        CFStringTransform(mutableString, nil, kCFStringTransformLatinHiragana, false)
        let latin = mutableString as String
        if latin != text {
            // Convert kanji to hiragana via Latin
            let mutable2 = NSMutableString(string: text)
            CFStringTransform(mutable2, nil, kCFStringTransformToLatin, false)
            let latinStr = mutable2 as String
            let mutable3 = NSMutableString(string: latinStr)
            CFStringTransform(mutable3, nil, kCFStringTransformLatinHiragana, false)
            let result = mutable3 as String
            return result != text ? result : nil
        }
        return nil
    }
}
