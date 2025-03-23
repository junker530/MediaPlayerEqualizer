import SwiftUI
import AVFoundation
import MediaPlayer

class MusicPlayerViewModel: ObservableObject {
    @Published var currentTime: Double = 0
    @Published var totalTime: Double = 0
    @Published var isPlaying: Bool = false
    @Published var currentSongIndex: Int = 0
    @Published var isSeeking: Bool = false
    
    var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var delegate: AudioPlayerDelegate?
    let playlistManager: MusicPlaylistManager
    private let musicPlayManager = MusicPlayManager()
    
    init(playlistManager: MusicPlaylistManager) {
        self.playlistManager = playlistManager
        self.delegate = AudioPlayerDelegate(viewModel: self)
    }
    
    func getCurrentSong() -> MusicItem? {
        guard !playlistManager.currentPlaylist.isEmpty else { return nil }
        return playlistManager.currentPlaylist[currentSongIndex]
    }
    
    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func setupAudioPlayer(useCompletionHandler: Bool = false) {
        handleStopAudio()
        
        guard let currentSong = getCurrentSong() else { return }
        
        do {
            if let assetURL = currentSong.assetURL {
                audioPlayer = try AVAudioPlayer(contentsOf: assetURL)
                audioPlayer?.delegate = delegate
                audioPlayer?.prepareToPlay()
                totalTime = audioPlayer?.duration ?? 0
                currentTime = 0
            }
            
            musicPlayManager.resetSeekOffset()
            
            if useCompletionHandler {
                try musicPlayManager.prepare(currentSong) { [weak self] in
                    DispatchQueue.main.async {
                        self?.handleNextSong()
                    }
                }
            } else {
                try musicPlayManager.prepare(currentSong)
            }

            
            startTimer()
        } catch {
            print("Error loading audio file: \(error)")
        }
    }


    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard !self.isSeeking else { return }
            
            self.currentTime = self.musicPlayManager.getCurrentTime()
            
            // 再生が終了したら次の曲へ進む（1回だけ実行）
            if self.currentTime >= self.totalTime, self.isPlaying {
                self.isPlaying = false  // 二重呼び出し防止
                self.handleNextSong()
            }
        }
    }



    func seekAudio(to time: Double) {
        guard let song = getCurrentSong() else { return }
        do {
            try musicPlayManager.seek(to: time, in: song)
            currentTime = time
        } catch {
            print("Seek failed: \(error)")
        }
    }

    func handlePlayPause() {
        if isPlaying {
            musicPlayManager.pause()
            // 停止しないので currentTime は保持される
            isPlaying = false
            timer?.invalidate()  // タイマーだけ止める
        } else {
            try? musicPlayManager.play()
            isPlaying = true
            startTimer()
        }
    }
    
    func handleSkipForward() {
        guard let player = audioPlayer else { return }
        let newTime = min(player.currentTime + 15, totalTime)
        player.currentTime = newTime
        currentTime = newTime
    }
    
    func handleSkipBackward() {
        guard let player = audioPlayer else { return }
        let newTime = max(player.currentTime - 15, 0)
        player.currentTime = newTime
        currentTime = newTime
    }
    
    func handleNextSong() {
        guard !playlistManager.currentPlaylist.isEmpty else { return }
        currentSongIndex = (currentSongIndex + 1) % playlistManager.currentPlaylist.count
        handleStopAudio()
        setupAudioPlayer(useCompletionHandler: false)  // ← completionHandlerなし
        playCurrentSong()
    }

    
    func handlePreviousSong() {
        guard !playlistManager.currentPlaylist.isEmpty else { return }
        currentSongIndex = (currentSongIndex - 1 + playlistManager.currentPlaylist.count) % playlistManager.currentPlaylist.count
        handleStopAudio()
        setupAudioPlayer()
        playCurrentSong()
    }
    
    func handleStopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        musicPlayManager.stop()
        isPlaying = false
        currentTime = 0
        totalTime = 0
        timer?.invalidate()
        timer = nil
    }
    
    private func playCurrentSong() {
        try? musicPlayManager.play()
        isPlaying = true
        startTimer()
    }
    
    
}

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private weak var viewModel: MusicPlayerViewModel?
    
    init(viewModel: MusicPlayerViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard let viewModel = viewModel else { return }
        
        DispatchQueue.main.async {
            viewModel.handleNextSong()
            if let player = viewModel.audioPlayer {
                player.play()
                viewModel.isPlaying = true
            }
        }
    }
}

struct MusicPlayerView: View {
    @StateObject private var playlistManager = MusicPlaylistManager()
    @StateObject private var viewModel: MusicPlayerViewModel
    @State private var showPlaylistPicker = false
    @State private var showEqualizerView = false
    
    init() {
        let manager = MusicPlaylistManager()
        _playlistManager = StateObject(wrappedValue: manager)
        _viewModel = StateObject(wrappedValue: MusicPlayerViewModel(playlistManager: manager))
    }
    
    var body: some View {
        ZStack {
            Image("image4").resizable().ignoresSafeArea()
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.clear)
                .background(
                    TransparentBlurView(removeFilters: true)
                        .blur(radius: 25, opaque: true)
                        .background(Color.white.opacity(0.05))
                )
                .clipShape(.rect(cornerRadius: 25, style: .continuous))
                .background(
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .stroke(.white.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 10)
                .ignoresSafeArea()
            VStack {
                Text("Best Vibes of the Week")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                if let currentSong = viewModel.getCurrentSong() {
                    CarouselCardView(currentSong: currentSong)
                        .transition(.move(edge: .leading))
                        .animation(.easeInOut, value: viewModel.currentSongIndex)
                        .padding([.top, .bottom])
                } else {
                    CarouselCardView(currentSong: nil)
                        .padding([.top, .bottom])
                }
                
                Slider(
                    value: $viewModel.currentTime,
                    in: 0...(viewModel.totalTime > 0 ? viewModel.totalTime : 1),
                    step: 1
                ) { editing in
                    viewModel.isSeeking = editing
                    if !editing {
                        viewModel.seekAudio(to: viewModel.currentTime)
                    }
                }
                .accentColor(.black.opacity(0.5))
                .padding(.horizontal)
                .disabled(viewModel.getCurrentSong() == nil || viewModel.totalTime <= 0)
                
                HStack {
                    Text(viewModel.formatTime(viewModel.currentTime))
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.5))
                    
                    Spacer()
                    
                    Text(viewModel.formatTime(viewModel.totalTime))
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.5))
                }
                .padding(.horizontal)
                
                HStack {
                    Button(action: viewModel.handleSkipBackward) {
                        Image(systemName: "15.arrow.trianglehead.counterclockwise")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                    
                    Button(action: viewModel.handlePreviousSong) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                    
                    Button(action: viewModel.handlePlayPause) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.3))
                                .frame(width: 85, height: 85)
                            
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                    
                    Button(action: viewModel.handleNextSong) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                    
                    Button(action: viewModel.handleSkipForward) {
                        Image(systemName: "15.arrow.trianglehead.clockwise")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                }
                .padding(.top, 30)
                
                HStack {
                    Button(action: { showEqualizerView = true}) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "repeat")
                            .font(.title2)
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "shuffle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                    
                    Spacer()
                    
                    Button(action: { showPlaylistPicker = true }) {
                        Image(systemName: "text.badge.plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 30)
            }
            .padding()
        }
        .sheet(isPresented: $showPlaylistPicker) {
            PlaylistPickerView(playlistManager: playlistManager) { selectedPlaylist in
                let wasPlaying = viewModel.isPlaying
                let currentPlaylistId = playlistManager.currentPlaylistId
                
                if currentPlaylistId != selectedPlaylist.persistentID {
                    viewModel.handleStopAudio()
                    playlistManager.loadPlaylist(selectedPlaylist)
                    viewModel.currentSongIndex = 0
                    viewModel.setupAudioPlayer()
                    if wasPlaying {
                        viewModel.audioPlayer?.play()
                        viewModel.isPlaying = true
                    }
                } else {
                    print("同じプレイリストが選択されました。再生を継続します。")
                }
            }
        }
        .sheet(isPresented: $showEqualizerView) {
            if #available(iOS 16.0, *) {
                EqualizerView(isPresented: $showEqualizerView)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            } else {
                EqualizerView(isPresented: $showEqualizerView)
                // iOS 15など古いOSでは通常の全画面モーダル表示
            }
        }
        .onAppear {
            viewModel.setupAudioPlayer()
        }
        .onDisappear {
            viewModel.handleStopAudio()
        }
    }
}

#Preview {
    MusicPlayerView()
}
