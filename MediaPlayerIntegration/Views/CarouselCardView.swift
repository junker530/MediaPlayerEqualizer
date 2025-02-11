import SwiftUI

struct CarouselCardView: View {
    let currentSong: MusicItem
    
    var body: some View {
        VStack {
            if let artwork = currentSong.artwork {
                Image(uiImage: artwork.image(at: CGSize(width: 300, height: 300)) ?? UIImage())
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            
            Text(currentSong.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(currentSong.artist)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(height: 300)
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(15)
    }
}
