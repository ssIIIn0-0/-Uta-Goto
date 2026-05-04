import Foundation
import MusicKit
import Combine

final class AudioSyncService: ObservableObject {
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isPlaying: Bool = false
    @Published var activeLineIndex: Int = 0
    @Published var errorMessage: String?

    private let player = ApplicationMusicPlayer.shared
    private var timer: AnyCancellable?
    private var timestamps: [Double] = []
    private var stateObservation: AnyCancellable?

    init() {
        stateObservation = player.state.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                let playing = self.player.state.playbackStatus == .playing
                if self.isPlaying != playing {
                    self.isPlaying = playing
                    if playing {
                        self.startTimer()
                    } else {
                        self.timer?.cancel()
                    }
                }
            }
        }
    }

    func load(song: Song) {
        stop()
        errorMessage = nil

        guard let musicID = song.appleMusicID else {
            return
        }

        timestamps = song.sortedLyricLines.compactMap { $0.timestampStart }
        duration = song.sortedLyricLines.last?.timestampEnd ?? 0

        Task {
            do {
                guard let musicSong = try await AppleMusicService.shared.fetchSong(id: musicID) else {
                    await MainActor.run { errorMessage = "Apple Music에서 곡을 찾을 수 없습니다." }
                    return
                }

                await MainActor.run {
                    if let dur = musicSong.duration {
                        duration = dur
                    }
                }

                player.queue = [musicSong]
                try await player.prepareToPlay()
            } catch {
                await MainActor.run {
                    errorMessage = "음악 로드 실패: \(error.localizedDescription)"
                }
            }
        }
    }

    func play() {
        Task {
            do {
                try await player.play()
            } catch {
                await MainActor.run {
                    errorMessage = "재생 실패: \(error.localizedDescription)"
                }
            }
        }
    }

    func pause() {
        player.pause()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to seconds: Double) {
        let clamped = max(0, min(seconds, duration))
        player.playbackTime = clamped
        currentTime = clamped
        updateActiveLineIndex()
    }

    func skipForward(_ seconds: Double = 15) {
        seek(to: currentTime + seconds)
    }

    func skipBackward(_ seconds: Double = 15) {
        seek(to: currentTime - seconds)
    }

    func stop() {
        player.pause()
        timer?.cancel()
        isPlaying = false
        currentTime = 0
        duration = 0
        activeLineIndex = 0
    }

    var hasAudio: Bool {
        player.isPreparedToPlay || player.state.playbackStatus == .playing
    }

    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let time = self.player.playbackTime
                if time.isFinite {
                    self.currentTime = time
                    self.updateActiveLineIndex()
                }
            }
    }

    private func updateActiveLineIndex() {
        let newIndex = activeLineIndex(at: currentTime, timestamps: timestamps)
        if newIndex != activeLineIndex {
            activeLineIndex = newIndex
        }
    }

    func activeLineIndex(at time: Double, timestamps: [Double]) -> Int {
        guard !timestamps.isEmpty else { return 0 }

        var low = 0
        var high = timestamps.count - 1

        if time < timestamps[0] { return 0 }
        if time >= timestamps[high] { return high }

        while low <= high {
            let mid = (low + high) / 2
            if timestamps[mid] <= time {
                if mid + 1 < timestamps.count && timestamps[mid + 1] > time {
                    return mid
                }
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        return low
    }

    func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
