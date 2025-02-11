import SwiftUI

struct CarouselCardView: View {
    let currentSong: MusicItem
    
    var body: some View {
        VStack(spacing: 20) {
            // アートワークの表示
            if let artwork = currentSong.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 300, height: 300)) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 250, height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            
            // タイトルとアーティスト情報
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
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
