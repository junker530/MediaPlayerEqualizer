//
//  Glassmorphism Effect.swift
//  Yoga App Template
//
//  Created by Damra on 22.07.2024.
//

import Foundation
import SwiftUI

struct TransparentBlurView: UIViewRepresentable {

    var removeFilters: Bool = false
    
    func makeUIView(context: Context) -> TransparentBlurViewHelper {
        return TransparentBlurViewHelper(removeFilters: removeFilters)
    }
    
    func updateUIView(_ uiView: TransparentBlurViewHelper, context: Context) {
        
    }
    
    
}

class TransparentBlurViewHelper: UIVisualEffectView {
    init(removeFilters: Bool) {
        super.init(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        if subviews.indices.contains(1) {
            subviews[1].alpha = 0
        }
        if let backgroundLayer = layer.sublayers?.first {
            if removeFilters {
                backgroundLayer.filters = []
            } else {
                backgroundLayer.filters?.removeAll(where:  { items in
                    String(describing: items) != "gaussianBlur"
                })
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
    }
    
}
