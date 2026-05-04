import Foundation
import SwiftData

@MainActor
struct SampleData {
    static var previewContainer: ModelContainer = {
        let schema = Schema([
            Song.self,
            LyricLine.self,
            VocabEntry.self,
            WordAppearance.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = container.mainContext

            // Song 1: Lemon - Kenshi Yonezu
            let lemon = Song(title: "Lemon", artist: "米津玄師")

            let lemonLyrics: [(Double, String, String)] = [
                (12.34, "夢ならばどれほどよかったでしょう", "꿈이라면 얼마나 좋았을까"),
                (17.50, "未だにあなたのことを夢にみる", "아직도 당신을 꿈에서 봐요"),
                (22.80, "忘れた物を取りに帰るように", "잊어버린 것을 가지러 돌아가듯이"),
                (28.10, "古びた思い出の埃を払う", "오래된 추억의 먼지를 털어내요"),
                (34.50, "戻らない幸せがあることを", "돌아오지 않는 행복이 있다는 것을"),
                (39.20, "最後にあなたが教えてくれた", "마지막에 당신이 가르쳐 주었어요"),
                (44.80, "言えずに隠してた昏い過去も", "말하지 못하고 숨겨왔던 어두운 과거도"),
                (50.10, "あなたがいなきゃ永遠に昏いまま", "당신이 없으면 영원히 어두운 채로"),
                (56.30, "きっともうこれ以上傷つくことなど", "분명 이 이상 상처받는 일 따위는"),
                (61.80, "ありはしないとわかっている", "없을 거라는 걸 알고 있어요"),
                (67.20, "あの日の悲しみさえあの日の苦しみさえ", "그날의 슬픔조차 그날의 괴로움조차"),
                (73.50, "そのすべてを愛してたあなたとともに", "그 모든 것을 사랑했던 당신과 함께"),
                (80.00, "胸に残り離れない苦いレモンの匂い", "가슴에 남아 떠나지 않는 쓴 레몬의 향기"),
                (86.50, "雨が降り止むまでは帰れない", "비가 그칠 때까지는 돌아갈 수 없어요"),
                (91.80, "今でもあなたはわたしの光", "지금도 당신은 나의 빛")
            ]

            for (index, item) in lemonLyrics.enumerated() {
                let endTime = index + 1 < lemonLyrics.count ? lemonLyrics[index + 1].0 : item.0 + 5.0
                let line = LyricLine(
                    lineIndex: index,
                    originalText: item.1,
                    translationText: item.2,
                    timestampStart: item.0,
                    timestampEnd: endTime,
                    song: lemon
                )
                lemon.lyricLines.append(line)
            }

            context.insert(lemon)

            // Song 2: Homura - LiSA
            let homura = Song(title: "炎", artist: "LiSA")

            let homuraLyrics: [(Double, String, String)] = [
                (15.00, "さよならごっこもう何回目だっけ", "이별 놀이 벌써 몇 번째였더라"),
                (20.50, "僕らは関わりあうたび何か残して", "우리는 만날 때마다 무언가를 남기고"),
                (26.80, "うまくはいかぬこともあるけれど", "잘 되지 않는 일도 있지만"),
                (31.50, "夢のように消えてゆく", "꿈처럼 사라져 가는"),
                (35.20, "ひとときの瞬きを", "한때의 눈깜짝임을"),
                (40.00, "世界に打ちのめされて負ける意味を知った", "세계에 두들겨 맞고 지는 의미를 알았어"),
                (47.30, "それでも立ち上がることを諦めないでいたい", "그래도 일어서는 것을 포기하지 않고 싶어"),
                (54.00, "どうしたって消せない夢も止まれない今も", "어쩔 수 없이 지울 수 없는 꿈도 멈출 수 없는 지금도"),
                (61.50, "誰かのために強くなれるなら", "누군가를 위해 강해질 수 있다면"),
                (66.80, "ありがとう悲しみよ", "고마워 슬픔이여"),
                (71.20, "世界にうちのめされて負ける意味を知った", "세계에 두들겨 맞고 지는 의미를 알았어"),
                (78.00, "炎のように燃えて会いにいくよ", "불꽃처럼 타올라 만나러 갈게")
            ]

            for (index, item) in homuraLyrics.enumerated() {
                let endTime = index + 1 < homuraLyrics.count ? homuraLyrics[index + 1].0 : item.0 + 5.0
                let line = LyricLine(
                    lineIndex: index,
                    originalText: item.1,
                    translationText: item.2,
                    timestampStart: item.0,
                    timestampEnd: endTime,
                    song: homura
                )
                homura.lyricLines.append(line)
            }

            context.insert(homura)

            // Sample VocabEntries
            let sampleWords: [(String, String, String, String, JLPTLevel)] = [
                ("夢", "ゆめ", "꿈", "명사", .n3),
                ("忘れる", "わすれる", "잊다", "동사", .n4),
                ("幸せ", "しあわせ", "행복", "명사", .n3),
                ("教える", "おしえる", "가르치다", "동사", .n4),
                ("永遠", "えいえん", "영원", "명사", .n2),
                ("悲しみ", "かなしみ", "슬픔", "명사", .n3),
                ("苦しみ", "くるしみ", "괴로움", "명사", .n2),
                ("愛する", "あいする", "사랑하다", "동사", .n3),
                ("光", "ひかり", "빛", "명사", .n3),
                ("雨", "あめ", "비", "명사", .n5),
                ("強い", "つよい", "강하다", "형용사", .n4),
                ("消える", "きえる", "사라지다", "동사", .n3),
                ("立つ", "たつ", "서다", "동사", .n4),
                ("世界", "せかい", "세계", "명사", .n3),
                ("意味", "いみ", "의미", "명사", .n4),
                ("戻る", "もどる", "돌아가다", "동사", .n3),
                ("思い出", "おもいで", "추억", "명사", .n3),
                ("最後", "さいご", "마지막", "명사", .n4),
                ("過去", "かこ", "과거", "명사", .n3),
                ("帰る", "かえる", "돌아가다", "동사", .n5),
                ("今", "いま", "지금", "명사", .n5),
                ("誰", "だれ", "누구", "명사", .n5),
                ("炎", "ほのお", "불꽃", "명사", .n2),
                ("諦める", "あきらめる", "포기하다", "동사", .n2),
            ]

            for (word, reading, meaning, pos, level) in sampleWords {
                let entry = VocabEntry(
                    word: word,
                    reading: reading,
                    meaning: meaning,
                    partOfSpeech: pos,
                    jlptLevel: level,
                    reviewCount: Int.random(in: 1...5)
                )
                context.insert(entry)

                // Link to songs
                let appearance1 = WordAppearance(
                    vocabEntry: entry,
                    song: lemon,
                    lyricLineText: lemonLyrics[0].1,
                    lyricLineIndex: 0
                )
                context.insert(appearance1)
                entry.appearances.append(appearance1)
                lemon.wordAppearances.append(appearance1)

                if Bool.random() {
                    let appearance2 = WordAppearance(
                        vocabEntry: entry,
                        song: homura,
                        lyricLineText: homuraLyrics[0].1,
                        lyricLineIndex: 0
                    )
                    context.insert(appearance2)
                    entry.appearances.append(appearance2)
                    homura.wordAppearances.append(appearance2)
                }
            }

            try context.save()
            return container
        } catch {
            fatalError("SampleData 생성 실패: \(error)")
        }
    }()
}
