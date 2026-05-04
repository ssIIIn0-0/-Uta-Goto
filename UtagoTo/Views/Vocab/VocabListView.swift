import SwiftUI
import SwiftData

struct VocabListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var vocabVM: VocabViewModel
    var onNavigateToSong: ((Song) -> Void)?

    private let levels: [JLPTLevel?] = [nil, .n5, .n4, .n3, .n2, .n1]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                levelPicker
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                if vocabVM.filteredEntries.isEmpty {
                    EmptyStateView(
                        icon: "book",
                        title: "단어가 없습니다",
                        message: "노래 가사에서 단어를 탭하면 자동으로 추가됩니다."
                    )
                } else {
                    List {
                        ForEach(vocabVM.filteredEntries, id: \.id) { entry in
                            NavigationLink {
                                WordDetailView(
                                    entry: entry,
                                    vocabVM: vocabVM,
                                    onNavigateToSong: onNavigateToSong
                                )
                            } label: {
                                VocabCardView(entry: entry)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    vocabVM.deleteEntry(entry)
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    vocabVM.toggleFavorite(entry)
                                } label: {
                                    Label(
                                        entry.isFavorite ? "즐겨찾기 해제" : "즐겨찾기",
                                        systemImage: entry.isFavorite ? "star.slash" : "star.fill"
                                    )
                                }
                                .tint(.yellow)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("단어장")
            .searchable(text: $vocabVM.searchText, prompt: "단어, 읽기, 뜻 검색")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    sortMenu
                }
            }
            .onAppear {
                vocabVM.setup(context: modelContext)
            }
            .alert("오류", isPresented: .init(
                get: { vocabVM.errorMessage != nil },
                set: { if !$0 { vocabVM.errorMessage = nil } }
            )) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(vocabVM.errorMessage ?? "")
            }
        }
    }

    private var levelPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(levels, id: \.self) { level in
                    let isSelected = vocabVM.selectedLevel == level
                    Button {
                        vocabVM.selectedLevel = level
                    } label: {
                        Text(level?.displayName ?? "전체")
                            .font(.subheadline.bold())
                            .foregroundStyle(isSelected ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                isSelected ? (level?.color ?? Color.accentColor) : Color(.systemGray5),
                                in: Capsule()
                            )
                    }
                    .accessibilityLabel(level?.displayName ?? "전체")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(VocabViewModel.SortOption.allCases, id: \.self) { option in
                Button {
                    vocabVM.sortOption = option
                } label: {
                    HStack {
                        Text(option.rawValue)
                        if vocabVM.sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .accessibilityLabel("정렬")
    }
}

#Preview {
    VocabListView(vocabVM: VocabViewModel())
        .modelContainer(SampleData.previewContainer)
}
