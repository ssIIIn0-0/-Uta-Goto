import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        }
    }
}

#Preview {
    EmptyStateView(
        icon: "music.note",
        title: "노래가 없습니다",
        message: "오른쪽 상단 + 버튼으로 노래를 추가해보세요."
    )
}
