import Foundation

struct JapanesePronunciationService {
    static let shared = JapanesePronunciationService()

    func toKatakana(_ hiragana: String) -> String {
        var result = ""
        for scalar in hiragana.unicodeScalars {
            // Hiragana range: U+3041 - U+3096 → Katakana: U+30A1 - U+30F6
            if scalar.value >= 0x3041 && scalar.value <= 0x3096 {
                result += String(Unicode.Scalar(scalar.value + 0x60)!)
            } else {
                result += String(scalar)
            }
        }
        return result
    }

    func toKorean(_ reading: String) -> String {
        var result = ""
        let chars = Array(reading)
        var i = 0

        while i < chars.count {
            if i + 1 < chars.count {
                let digraph = String(chars[i]) + String(chars[i + 1])
                if let korean = digraphMap[digraph] {
                    result += korean
                    i += 2
                    continue
                }
            }

            if String(chars[i]) == "っ" || String(chars[i]) == "ッ" {
                if i + 1 < chars.count {
                    result += sokuonPrefix(for: chars[i + 1])
                }
                i += 1
                continue
            }

            if String(chars[i]) == "ん" || String(chars[i]) == "ン" {
                result += nSound(next: i + 1 < chars.count ? chars[i + 1] : nil)
                i += 1
                continue
            }

            if String(chars[i]) == "ー" {
                i += 1
                continue
            }

            let ch = String(chars[i])
            if let korean = singleMap[ch] {
                result += korean
            } else {
                result += ch
            }
            i += 1
        }

        return result
    }

    private func sokuonPrefix(for next: Character) -> String {
        let s = String(next)
        if "かきくけこ".contains(s) || "カキクケコ".contains(s) { return "ㄱ" }
        if "さしすせそ".contains(s) || "サシスセソ".contains(s) { return "ㅅ" }
        if "たちつてと".contains(s) || "タチツテト".contains(s) { return "ㅅ" }
        if "ぱぴぷぺぽ".contains(s) || "パピプペポ".contains(s) { return "ㅂ" }
        return ""
    }

    private func nSound(next: Character?) -> String {
        guard let next else { return "은" }
        let s = String(next)
        if "まみむめもばびぶべぼぱぴぷぺぽ".contains(s) { return "ㅁ" }
        if "なにぬねの".contains(s) { return "ㄴ" }
        if "かきくけこがぎぐげご".contains(s) { return "ㅇ" }
        return "ㄴ"
    }

    private let digraphMap: [String: String] = [
        "きゃ": "캬", "きゅ": "큐", "きょ": "쿄",
        "しゃ": "샤", "しゅ": "슈", "しょ": "쇼",
        "ちゃ": "차", "ちゅ": "추", "ちょ": "초",
        "にゃ": "냐", "にゅ": "뉴", "にょ": "뇨",
        "ひゃ": "햐", "ひゅ": "휴", "ひょ": "효",
        "みゃ": "먀", "みゅ": "뮤", "みょ": "묘",
        "りゃ": "랴", "りゅ": "류", "りょ": "료",
        "ぎゃ": "갸", "ぎゅ": "규", "ぎょ": "교",
        "じゃ": "자", "じゅ": "주", "じょ": "조",
        "びゃ": "뱌", "びゅ": "뷰", "びょ": "뵤",
        "ぴゃ": "퍄", "ぴゅ": "퓨", "ぴょ": "표",
    ]

    private let singleMap: [String: String] = [
        "あ": "아", "い": "이", "う": "우", "え": "에", "お": "오",
        "か": "카", "き": "키", "く": "쿠", "け": "케", "こ": "코",
        "さ": "사", "し": "시", "す": "스", "せ": "세", "そ": "소",
        "た": "타", "ち": "치", "つ": "츠", "て": "테", "と": "토",
        "な": "나", "に": "니", "ぬ": "누", "ね": "네", "の": "노",
        "は": "하", "ひ": "히", "ふ": "후", "へ": "헤", "ほ": "호",
        "ま": "마", "み": "미", "む": "무", "め": "메", "も": "모",
        "や": "야", "ゆ": "유", "よ": "요",
        "ら": "라", "り": "리", "る": "루", "れ": "레", "ろ": "로",
        "わ": "와", "を": "오", "ん": "은",
        "が": "가", "ぎ": "기", "ぐ": "구", "げ": "게", "ご": "고",
        "ざ": "자", "じ": "지", "ず": "즈", "ぜ": "제", "ぞ": "조",
        "だ": "다", "ぢ": "지", "づ": "즈", "で": "데", "ど": "도",
        "ば": "바", "び": "비", "ぶ": "부", "べ": "베", "ぼ": "보",
        "ぱ": "파", "ぴ": "피", "ぷ": "푸", "ぺ": "페", "ぽ": "포",
        // Katakana
        "ア": "아", "イ": "이", "ウ": "우", "エ": "에", "オ": "오",
        "カ": "카", "キ": "키", "ク": "쿠", "ケ": "케", "コ": "코",
        "サ": "사", "シ": "시", "ス": "스", "セ": "세", "ソ": "소",
        "タ": "타", "チ": "치", "ツ": "츠", "テ": "테", "ト": "토",
        "ナ": "나", "ニ": "니", "ヌ": "누", "ネ": "네", "ノ": "노",
        "ハ": "하", "ヒ": "히", "フ": "후", "ヘ": "헤", "ホ": "호",
        "マ": "마", "ミ": "미", "ム": "무", "メ": "메", "モ": "모",
        "ヤ": "야", "ユ": "유", "ヨ": "요",
        "ラ": "라", "リ": "리", "ル": "루", "レ": "레", "ロ": "로",
        "ワ": "와", "ヲ": "오", "ン": "은",
        "ガ": "가", "ギ": "기", "グ": "구", "ゲ": "게", "ゴ": "고",
        "ザ": "자", "ジ": "지", "ズ": "즈", "ゼ": "제", "ゾ": "조",
        "ダ": "다", "ヂ": "지", "ヅ": "즈", "デ": "데", "ド": "도",
        "バ": "바", "ビ": "비", "ブ": "부", "ベ": "베", "ボ": "보",
        "パ": "파", "ピ": "피", "プ": "푸", "ペ": "페", "ポ": "포",
    ]
}
