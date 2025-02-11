import SwiftUI
import AVFoundation
import MediaPlayer

struct MusicPlayerView: View {
    @StateObject private var playlistManager = MusicPlaylistManager()
    @State private var currentTime: Double = 0
    @State private var totalTime: Double = 0
    @State private var isPlaying: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var timer: Timer?
    @State private var currentSongIndex: Int = 0
    @State private var showPlaylistPicker = false
    @State private var isSeeking: Bool = false
    
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
                
                if let currentSong = getCurrentSong() {
                    CarouselCardView(currentSong: currentSong)
                        .transition(.move(edge: .leading))
                        .animation(.easeInOut, value: currentSongIndex)
                        .padding([.top, .bottom])
                }
                
                Slider(
                    value: $currentTime,
                    in: 0...(totalTime > 0 ? totalTime : 1),
                    step: 1
                ) { editing in
                    isSeeking = editing
                    if !editing {
                        seekAudio(to: currentTime)
                    }
                }
                .accentColor(.black.opacity(0.5))
                .padding(.horizontal)
                .disabled(totalTime <= 0)
                
                HStack {
                    Text(formatTime(currentTime))
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.5))
                    
                    Spacer()
                    
                    Text(formatTime(totalTime))
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.5))
                }
                .padding(.horizontal)
                
                HStack {
                    Button(action: handleSkipBackward) {
                        Image(systemName: "15.arrow.trianglehead.counterclockwise")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Button(action: handlePreviousSong) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Button(action: handlePlayPause) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.3))
                                .frame(width: 85, height: 85)
                            
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    
                    Button(action: handleNextSong) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Button(action: handleSkipForward) {
                        Image(systemName: "15.arrow.trianglehead.clockwise")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .padding(.top, 30)
                
                HStack {
                    Button(action: {}) {
                        Image(systemName: "bookmark")
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
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "shuffle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
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
                let wasPlaying = isPlaying
                let currentPlaylistId = playlistManager.currentPlaylistId
                
                if currentPlaylistId != selectedPlaylist.persistentID {
                    handleStopAudio()
                    playlistManager.loadPlaylist(selectedPlaylist)
                    currentSongIndex = 0
                    setupAudioPlayer()
                    if wasPlaying {
                        audioPlayer?.play()
                        isPlaying = true
                    }
                } else {
                    print("同じプレイリストが選択されました。再生を継続します。")
                }
            }
        }
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            handleStopAudio()
        }
    }
    
    private func getCurrentSong() -> MusicItem? {
        guard !playlistManager.currentPlaylist.isEmpty else { return nil }
        return playlistManager.currentPlaylist[currentSongIndex]
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func setupAudioPlayer() {
        handleStopAudio()
        
        guard let currentSong = getCurrentSong(),
              let assetURL = currentSong.assetURL else {
            print("Error: Song file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: assetURL)
            audioPlayer?.prepareToPlay()
            totalTime = audioPlayer?.duration ?? 0
            currentTime = 0
            startTimer()
        } catch {
            print("Error loading audio file: \(error)")
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = audioPlayer, !isSeeking {
                currentTime = player.currentTime
            }
        }
    }
    
    private func seekAudio(to time: Double) {
        audioPlayer?.currentTime = time
        if isPlaying {
            audioPlayer?.play()
        }
    }
    
    private func handlePlayPause() {
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
            startTimer()
        }
        isPlaying.toggle()
    }
    
    private func handleSkipForward() {
        guard let player = audioPlayer else { return }
        let newTime = min(player.currentTime + 15, totalTime)
        player.currentTime = newTime
        currentTime = newTime
    }
    
    private func handleSkipBackward() {
        guard let player = audioPlayer else { return }
        let newTime = max(player.currentTime - 15, 0)
        player.currentTime = newTime
        currentTime = newTime
    }
    
    private func handleNextSong() {
        guard !playlistManager.currentPlaylist.isEmpty else { return }
        currentSongIndex = (currentSongIndex + 1) % playlistManager.currentPlaylist.count
        handleStopAudio()
        setupAudioPlayer()
        if isPlaying {
            audioPlayer?.play()
        }
    }
    
    private func handlePreviousSong() {
        guard !playlistManager.currentPlaylist.isEmpty else { return }
        currentSongIndex = (currentSongIndex - 1 + playlistManager.currentPlaylist.count) % playlistManager.currentPlaylist.count
        handleStopAudio()
        setupAudioPlayer()
        if isPlaying {
            audioPlayer?.play()
        }
    }
    
    private func handleStopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        totalTime = 0
        timer?.invalidate()
        timer = nil
    }
}
