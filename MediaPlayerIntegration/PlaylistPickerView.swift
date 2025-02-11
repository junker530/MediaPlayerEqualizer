import SwiftUI
import MediaPlayer

struct PlaylistPickerView: View {
    let playlistManager: MusicPlaylistManager
    let onSelect: (MPMediaPlaylist) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                switch playlistManager.authorizationStatus {
                case .authorized:
                    List(playlistManager.playlists, id: \.persistentID) { playlist in
                        Button(action: {
                            onSelect(playlist)
                            dismiss()
                        }) {
                            Text(playlist.name ?? "Unknown Playlist")
                        }
                    }
                case .denied, .restricted:
                    VStack {
                        Text("ミュージックライブラリへのアクセスが許可されていません")
                            .padding()
                        Button("設定を開く") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                case .notDetermined:
                    VStack {
                        Text("ミュージックライブラリへのアクセスを許可してください")
                            .padding()
                        Button("許可する") {
                            playlistManager.checkAuthorization()
                        }
                    }
                @unknown default:
                    Text("エラーが発生しました")
                }
            }
            .navigationTitle("プレイリストを選択")
        }
    }
}
