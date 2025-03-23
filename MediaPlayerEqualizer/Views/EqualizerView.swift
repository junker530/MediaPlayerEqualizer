//
//  EqualizerView.swift
//  MediaPlayerEqualizer
//
//  Created by Shota Sakoda on 2025/03/23.
//

// EqualizerView.swift

import SwiftUI

struct EqualizerView: View {
    @Binding var isPresented: Bool
    @ObservedObject var manager: MusicPlayManager  // ← 追加！
    @State private var bandValues: [Double] = [0,0,0,0,0]  // 初期値は manager からも取得可
    @State private var clearBass: Double = 0 // Clear Bassの値
    let frequencies = ["400", "1k", "2.5k", "6.3k", "16k"] // 周波数ラベル
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // 背景を黒に
            
            VStack(spacing: 30) {
                // イコライザー部分
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // dBラベル（-10, 0, +10）をメモリと正確に配置
                        ZStack {
                            Text("-10")
                                .foregroundColor(.white)
                                .font(.caption)
                                .position(x: 20, y: geometry.size.height - (0.0 * geometry.size.height / 20.0))
                            Text("0")
                                .foregroundColor(.white)
                                .font(.caption)
                                .position(x: 20, y: geometry.size.height - (10.0 * geometry.size.height / 20.0))
                            Text("+10")
                                .foregroundColor(.white)
                                .font(.caption)
                                .position(x: 20, y: geometry.size.height - (20.0 * geometry.size.height / 20.0))
                        }
                        
                        // 縦スライダーと周波数ラベル
                        HStack(spacing: 0) {
                            ForEach(0..<5) { i in
                                VStack {
                                    VerticalSlider(value: $bandValues[i], height: geometry.size.height, loop: i)
                                        .onChange(of: bandValues[i]) { newValue in
                                            manager.updateGain(band: i, value: newValue)
                                        }
                                    Spacer().frame(height: 15)
                                    
                                    Text(frequencies[i])
                                        .foregroundColor(.white)
                                        .font(.caption) // dBラベルと同じサイズ
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.leading, 20) // dBラベル分のスペース
                    }
                }
                .frame(height: 350) // イコライザーの高さ固定
                
                Divider().background(Color.white) // 区切り線
                    .padding(.top, 20)
                
                // Clear Bass部分
                VStack(spacing: 10) {
                    Text("CLEAR BASS")
                        .foregroundColor(.white)
                        .font(.headline)
                    HorizontalSlider(value: $clearBass)
                        .frame(height: 20)
                    // Clear Bassのラベルをメモリに合わせ、サイズを小さく
                    HStack {
                        Text("-10").font(.caption2)
                        Spacer()
                        Text("0").font(.caption2)
                        Spacer()
                        Text("+10").font(.caption2)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal)
                }
            }
            .padding()
        }
    }
}

// 縦スライダー（-10が下、+10が上）
struct VerticalSlider: View {
    @Binding var value: Double
    let height: CGFloat
    let loop: Int
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 2, height: height)
            // 1dBごとのメモリ
            if loop != 4 {
                ForEach(-10...10, id: \.self) { mark in
                    let y = (Double(mark) + 10) / 20 * height
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: mark % 5 == 0 ? 15 : 10, height: 1)
                        .position(x: 55, y: height - y)
                }
            }
            // つまみ
            Circle()
                .fill(Color.white)
                .frame(width: 20)
                .position(x: 20, y: (10 - value) / 20 * height)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            let y = gesture.location.y
                            let newValue = 10 - (y / height) * 20
                            value = max(-10, min(10, round(newValue)))
                        }
                )
        }
        .frame(width: 40, height: height)
    }
}

// 横スライダー
struct HorizontalSlider: View {
    @Binding var value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                
                // 1dBごとのメモリ
                ForEach(-10...10, id: \.self) { mark in
                    let scaleFactor = 0.86 // メモリ全体を86%の幅に圧縮（調整可能）
                    let x = (Double(mark) + 10) / 20 * geometry.size.width * scaleFactor
                    let offsetX = (1 - scaleFactor) / 2 * geometry.size.width // 中央に寄せる
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 1, height: mark % 5 == 0 ? 10 : 5)
                        .position(x: x + offsetX, y: 5) // 中央に配置
                }
                // つまみ
                Circle()
                    .fill(Color.white)
                    .frame(width: 20)
                    .position(x: (value + 10) / 20 * geometry.size.width, y: 10)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let x = gesture.location.x
                                let newValue = -10 + (x / geometry.size.width) * 20
                                value = max(-10, min(10, round(newValue)))
                            }
                    )
            }
        }
    }
}

#Preview {
    EqualizerView(isPresented: .constant(true), manager: MusicPlayManager())
}
