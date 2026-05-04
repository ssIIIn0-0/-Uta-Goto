import SwiftUI

struct JLPTBadgeView: View {
    let level: JLPTLevel

    var body: some View {
        Text(level.displayName)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(level.color, in: RoundedRectangle(cornerRadius: 4))
            .accessibilityLabel("JLPT \(level.displayName) \(level.colorName)")
    }
}

#Preview {
    HStack {
        ForEach(JLPTLevel.allCases, id: \.self) { level in
            JLPTBadgeView(level: level)
        }
    }
    .padding()
}
