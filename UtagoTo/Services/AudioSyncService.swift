import Foundation
import AVFoundation
import Combine

final class AudioSyncService: ObservableObject {
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isPlaying: Bool = false
    @Published var activeLineIndex: Int = 0
    @Published var errorMessage: String?

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private var timestamps: [Double] = []

    func load(song: Song) {
        stop()
        errorMessage = nil

        var audioURL: URL?

        if let fileName = song.audioFileName {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("Audio").appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                audioURL = fileURL
            }
        }

        if audioURL == nil, let urlString = song.audioURLString, let url = URL(string: urlString) {
            if let host = url.host?.lowercased(),
               host.contains("youtube.com") || host.contains("youtu.be") {
                errorMessage = "YouTube URL은 직접 재생할 수 없습니다. 오디오 파일 직접 링크를 사용해주세요."
                return
            }
            audioURL = url
        }

        guard let url = audioURL else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            errorMessage = "오디오 세션 설정 실패: \(error.localizedDescription)"
            return
        }

        let item = AVPlayerItem(url: url)
        playerItem = item
        player = AVPlayer(playerItem: item)

        statusObservation = item.observe(\.status) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                switch item.status {
                case .failed:
                    self.errorMessage = "오디오를 불러올 수 없습니다: \(item.error?.localizedDescription ?? "알 수 없는 오류")"
                    self.player = nil
                    self.playerItem = nil
                case .readyToPlay:
                    let seconds = item.duration.seconds
                    if seconds.isFinite { self.duration = seconds }
                default:
                    break
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
            self?.removeTimeObserver()
        }

        timestamps = song.sortedLyricLines.compactMap { $0.timestampStart }
    }

    func play() {
        guard let player else { return }
        player.play()
        isPlaying = true
        startTimeObserver()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        removeTimeObserver()
    }

    func togglePlayPause() {
        if isPlaying { pause() } else { play() }
    }

    func seek(to seconds: Double) {
        let clamped = max(0, min(seconds, duration))
        player?.seek(to: CMTime(seconds: clamped, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = clamped
        updateActiveLineIndex()
    }

    func skipForward(_ seconds: Double = 15) { seek(to: currentTime + seconds) }
    func skipBackward(_ seconds: Double = 15) { seek(to: currentTime - seconds) }

    func stop() {
        removeTimeObserver()
        statusObservation?.invalidate()
        statusObservation = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        player?.pause()
        player = nil
        playerItem = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        activeLineIndex = 0
    }

    var hasAudio: Bool { player != nil }

    private func startTimeObserver() {
        removeTimeObserver()
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            self.currentTime = time.seconds
            self.updateActiveLineIndex()
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func updateActiveLineIndex() {
        let newIndex = activeLineIndex(at: currentTime, timestamps: timestamps)
        if newIndex != activeLineIndex { activeLineIndex = newIndex }
    }

    func activeLineIndex(at time: Double, timestamps: [Double]) -> Int {
        guard !timestamps.isEmpty else { return 0 }
        var low = 0, high = timestamps.count - 1
        if time < timestamps[0] { return 0 }
        if time >= timestamps[high] { return high }
        while low <= high {
            let mid = (low + high) / 2
            if timestamps[mid] <= time {
                if mid + 1 < timestamps.count && timestamps[mid + 1] > time { return mid }
                low = mid + 1
            } else { high = mid - 1 }
        }
        return low
    }

    func formatTime(_ seconds: Double) -> String {
        String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }
}
