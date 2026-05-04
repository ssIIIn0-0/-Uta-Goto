import SwiftUI

enum JLPTLevel: String, Codable, CaseIterable, Comparable {
    case n5, n4, n3, n2, n1, unknown

    var displayName: String {
        switch self {
        case .n5: return "N5"
        case .n4: return "N4"
        case .n3: return "N3"
        case .n2: return "N2"
        case .n1: return "N1"
        case .unknown: return "?"
        }
    }

    var color: Color {
        switch self {
        case .n5:      return Color(red: 0.298, green: 0.686, blue: 0.314)
        case .n4:      return Color(red: 0.129, green: 0.588, blue: 0.953)
        case .n3:      return Color(red: 1.0,   green: 0.596, blue: 0.0)
        case .n2:      return Color(red: 0.957, green: 0.263, blue: 0.212)
        case .n1:      return Color(red: 0.612, green: 0.153, blue: 0.69)
        case .unknown: return Color(.systemGray4)
        }
    }

    var colorName: String {
        switch self {
        case .n5: return "초록"
        case .n4: return "파랑"
        case .n3: return "주황"
        case .n2: return "빨강"
        case .n1: return "보라"
        case .unknown: return "회색"
        }
    }

    private var sortOrder: Int {
        switch self {
        case .n5: return 0
        case .n4: return 1
        case .n3: return 2
        case .n2: return 3
        case .n1: return 4
        case .unknown: return 5
        }
    }

    static func < (lhs: JLPTLevel, rhs: JLPTLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
