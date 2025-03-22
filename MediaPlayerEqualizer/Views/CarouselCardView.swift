import SwiftUI

struct CarouselCardView: View {
    let currentSong: MusicItem?
    
    var body: some View {
        VStack(spacing: 20) {
            if let currentSong = currentSong, let artwork = currentSong.artwork {
                // 曲が選択されていて、アートワークが存在する場合
                Image(uiImage: artwork.image(at: CGSize(width: 300, height: 300)) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 250, height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                
                VStack(spacing: 8) {
                    Text(currentSong.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(currentSong.artist)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            } else {
                // 曲が選択されていないか、アートワークが存在しない場合
                Image(systemName: "music.note")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 250, height: 250)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                
                VStack(spacing: 8) {
                    Text("No Track Selected")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Select a playlist to begin")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal)
    }
}
