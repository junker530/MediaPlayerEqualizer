import SwiftUI
import MediaPlayer

struct MusicItem: Identifiable, Equatable {
    let id: String
    let assetURL: URL?
    let title: String
    let artist: String
    let artwork: MPMediaItemArtwork?
    
    init(from mediaItem: MPMediaItem) {
        self.id = mediaItem.persistentID.description
        self.assetURL = mediaItem.assetURL
        self.title = mediaItem.title ?? "Unknown Title"
        self.artist = mediaItem.artist ?? "Unknown Artist"
        self.artwork = mediaItem.artwork
    }
}

class MusicPlaylistManager: ObservableObject {
    @Published var playlists: [MPMediaPlaylist] = []
    @Published var currentPlaylist: [MusicItem] = []
    @Published var authorizationStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    @Published var currentPlaylistId: MPMediaEntityPersistentID? = nil
    
    init() {
        checkAuthorization()
    }
    
    func checkAuthorization() {
        authorizationStatus = MPMediaLibrary.authorizationStatus()
        
        switch authorizationStatus {
        case .authorized:
            fetchPlaylists()
        case .notDetermined:
            MPMediaLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    self?.authorizationStatus = status
                    if status == .authorized {
                        self?.fetchPlaylists()
                    }
                }
            }
        default:
            break
        }
    }
    
    func fetchPlaylists() {
        let playlistQuery = MPMediaQuery.playlists()
        if let playlists = playlistQuery.collections as? [MPMediaPlaylist] {
            self.playlists = playlists
        }
    }
    
    func loadPlaylist(_ playlist: MPMediaPlaylist) {
        currentPlaylistId = playlist.persistentID
        currentPlaylist = playlist.items.map { MusicItem(from: $0) }
    }
}
