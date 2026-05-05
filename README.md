# UtagoTo (うたゴト)

<p align="center">
  <img src="https://github.com/user-attachments/assets/2ae9b328-5160-478d-a930-a1e3446c9a04" width="300" alt="UtagoTo 스크린샷" />
</p>

일본어 노래 가사를 통해 일본어를 학습하는 iOS 앱입니다.

노래를 검색하고, 동기화된 가사를 보며, 모르는 단어를 탭하면 뜻과 발음을 바로 확인할 수 있습니다.
가사의 한국어 번역은 OpenAI 기반 자체 백엔드에서 자동으로 제공됩니다.

## 주요 기능

- **노래 검색** — iTunes Search API로 일본 노래 검색 + LRCLIB에서 동기화 가사 자동 연결
- **가사 플레이어** — 타임스탬프 기반 가사 하이라이트 + 한국어 번역 동시 표시
- **단어 학습** — 가사의 단어를 탭하면 읽기/뜻/품사/JLPT 레벨 확인 + 단어장 저장
- **JLPT 레벨 표시** — 가사 내 단어를 N5~N1 레벨별 색상으로 구분
- **한국어 번역** — OpenAI(gpt-4o-mini)로 직역/의역 자동 번역 + 캐싱
- **사용자 사전** — 로컬 사전에 없는 단어에 한국어 뜻 직접 추가
- **YouTube Music 연동** — 앱에서 바로 YouTube Music으로 이동하여 재생

## 기술 스택

| 구분 | 기술 |
|------|------|
| iOS | Swift, SwiftUI, SwiftData |
| 백엔드 | NestJS, TypeScript, TypeORM |
| DB | SQLite (sql.js) — 번역 캐싱 |
| LLM | OpenAI gpt-4o-mini |
| 외부 API | iTunes Search, LRCLIB, Jisho.org, YouTube Data API v3 |

## 프로젝트 구조

**[아키텍처 다이어그램 (인터랙티브)](https://ssiiin0-0.github.io/-Uta-Goto/architecture.html)** — 클릭하여 확인

```
UtagoTo/
├── UtagoTo/                    # iOS 앱
│   ├── App/                    # 앱 진입점, DI 컨테이너
│   ├── Models/                 # SwiftData 모델 (Song, LyricLine, VocabEntry 등)
│   ├── ViewModels/             # MVVM 뷰모델 (Player, Library, Vocab)
│   ├── Views/
│   │   ├── Library/            # 노래 검색/추가/목록
│   │   ├── Player/             # 가사 플레이어, 단어 팝업
│   │   ├── Vocab/              # 단어장, 단어 상세
│   │   ├── Settings/           # 설정 (API 키)
│   │   └── Common/             # 공통 컴포넌트
│   ├── Services/               # API 클라이언트 및 비즈니스 로직
│   │   ├── LyricParserService  # LRC 파싱 + NLTokenizer 토큰화
│   │   ├── TranslationService  # 백엔드 번역 API 클라이언트
│   │   ├── JLPTDictionaryService # JLPT 사전 (8,225단어)
│   │   ├── UserDictionaryService # 사용자 추가 단어 사전
│   │   ├── JishoService        # Jisho.org API 연동
│   │   ├── ITunesSearchService # iTunes 곡 검색
│   │   ├── LRCLibService       # LRCLIB 가사 검색
│   │   ├── YouTubeService      # YouTube Data API
│   │   └── AudioSyncService    # 오디오 재생 + 가사 동기화
│   └── Resources/              # JLPT N1~N5 사전 JSON
│
└── backend/                    # NestJS 번역 서버
    └── src/
        └── translation/        # POST /translate/lyrics
            ├── controller      # 요청 처리
            ├── service         # OpenAI 호출 + 캐시 관리
            └── entity          # SQLite 캐시 테이블
```

## 설치 및 실행

### 사전 요구사항

- Xcode 16+
- Node.js 20+
- OpenAI API 키 ([platform.openai.com](https://platform.openai.com))
- YouTube Data API v3 키 (선택)

### 백엔드

```bash
cd backend
npm install

# .env 파일에 OpenAI API 키 설정
echo "OPENAI_API_KEY=sk-your-key-here" > .env
echo "PORT=3000" >> .env

# 서버 실행
npm run start:dev
```

서버가 `http://localhost:3000`에서 실행됩니다.

### iOS 앱

1. Xcode에서 `UtagoTo.xcodeproj` 열기
2. **시뮬레이터**: 그대로 빌드 및 실행
3. **실기기**: `UtagoTo/Services/TranslationService.swift`에서 `baseURL`을 Mac의 로컬 IP로 변경 필요 (같은 Wi-Fi 네트워크)

### API 키 설정

| API | 필수 여부 | 설정 위치 |
|-----|-----------|-----------|
| OpenAI | 필수 | `backend/.env` |
| YouTube Data API v3 | 선택 | 앱 내 설정 화면 |
| iTunes Search | 불필요 | - |
| LRCLIB | 불필요 | - |
| Jisho.org | 불필요 | - |
