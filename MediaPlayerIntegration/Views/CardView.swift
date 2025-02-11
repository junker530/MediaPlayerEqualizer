//
//  CardView.swift
//  MediaPlayerIntegration
//
//  Created by Damra on 11.11.2024.
//

import SwiftUI

struct CardView: View {
    let imageName: String
    let itemName: String

    var body: some View {
        VStack {
            // Card Image Placeholder
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(15)
    }
}
