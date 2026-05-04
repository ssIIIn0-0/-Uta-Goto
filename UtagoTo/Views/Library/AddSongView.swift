import SwiftUI

struct AddSongView: View {
    @Environment(\.dismiss) private var dismiss

    var onSave: (String, String, String, [String], String?, String?) -> Void

    @State private var title = ""
    @State private var artist = ""
    @State private var lrcContent = ""
    @State private var translationText = ""
    @State private var audioURLString = ""
    @State private var includeTranslation = true
    @State private var showValidationError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("곡 정보") {
                    TextField("제목", text: $title)
                    TextField("아티스트", text: $artist)
                }

                Section("오디오") {
                    TextField("오디오 URL (선택)", text: $audioURLString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    TextEditor(text: $lrcContent)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                } header: {
                    Text("LRC 가사")
                } footer: {
                    Text("[00:12.34]夢ならばどれほどよかったでしょう\n[00:15.20]目が覚めれば良かったのに")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Section {
                    Toggle("한국어 번역 포함", isOn: $includeTranslation)

                    if includeTranslation {
                        TextEditor(text: $translationText)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 120)
                    }
                } header: {
                    Text("번역")
                } footer: {
                    if includeTranslation {
                        Text("가사와 같은 줄 수로 입력하세요. 한 줄에 하나의 번역.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .navigationTitle("노래 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { saveAction() }
                        .bold()
                }
            }
            .alert("입력 오류", isPresented: $showValidationError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("제목과 가사는 필수 입력 항목입니다.")
            }
        }
    }

    private func saveAction() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLRC = lrcContent.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, !trimmedLRC.isEmpty else {
            showValidationError = true
            return
        }

        let translations: [String]
        if includeTranslation {
            translations = translationText.components(separatedBy: .newlines)
        } else {
            translations = []
        }

        let audioURL = audioURLString.trimmingCharacters(in: .whitespacesAndNewlines)

        onSave(
            trimmedTitle,
            artist.trimmingCharacters(in: .whitespacesAndNewlines),
            trimmedLRC,
            translations,
            nil,
            audioURL.isEmpty ? nil : audioURL
        )

        dismiss()
    }
}

#Preview {
    AddSongView { _, _, _, _, _, _ in }
}
