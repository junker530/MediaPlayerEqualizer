//
//  MusicPlayManager.swift
//  MediaPlayerIntegration
//
//  Created by Shota Sakoda on 2025/03/22.
//

import SwiftUI
import AVFoundation

class MusicPlayManager: ObservableObject {
    // プロパティ追加
    private var seekOffsetTime: TimeInterval = 0
    
    
    enum PlayStatus {
        case prepared
        case stopped
        case playing
        case paused
    }
    
    struct EQParameter {
        let type: AVAudioUnitEQFilterType
        let bandWidth: Float?
        let frequency: Float
        let gain: Float
    }
    
    @Published var playStatus: PlayStatus = .stopped
    
    //  10-Bands Parametric EQ
//    private var eqParameters: [EQParameter] = [
//        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 32.0, gain: 3.0),
//        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 64.0, gain: 3.0),
//        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 128.0, gain: 3.0),
//        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 256.0, gain: 2.0),
//        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 500.0, gain: 0.0),
//        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 1000.0, gain: -6.0),
//        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 2000.0, gain: -6.0),
//        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 4000.0, gain: -6.0),
//        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 8000.0, gain: -6.0),
//        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 16000.0, gain: -6.0)
//    ]
    private var eqParameters: [EQParameter] = [
        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 400.0, gain: 0.0),
        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 1000.0, gain: 0.0),
        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 2500.0, gain: 0.0),
        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 6300.0, gain: 0.0),
        EQParameter(type: .parametric, bandWidth: 1.0, frequency: 16000.0, gain: 0.0),
    ]
    
    public private(set) lazy var playerNode = AVAudioPlayerNode()
    private lazy var engine = AVAudioEngine()
    private var eqNode: AVAudioUnitEQ
    
    private var routeChangeNotificationObserver: NSObjectProtocol?
    
    init() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Failed to configure AVAudioSession: \(error)")
        }
        
        self.eqNode = AVAudioUnitEQ(numberOfBands: self.eqParameters.count)
        self.eqNode.bands.enumerated().forEach { index, param in
            param.filterType = self.eqParameters[index].type
            param.bypass = false
            if let bandWidth = self.eqParameters[index].bandWidth {
                param.bandwidth = bandWidth
            }
            param.frequency = self.eqParameters[index].frequency
            param.gain = self.eqParameters[index].gain
        }
        
        self.engine.attach(self.playerNode)
        self.engine.attach(self.eqNode)
        
        self.registerRouteChangeObserver()
    }

    
    deinit {
        self.removeRouteChangeObserver()
    }
    
    private func registerRouteChangeObserver() {
        self.routeChangeNotificationObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
            }
            
            DispatchQueue.main.async {
                switch reason {
                case .newDeviceAvailable:
                    try? self?.play()
                case .oldDeviceUnavailable:
                    self?.pause()
                default: break
                }
            }
        }
    }
    
    private func removeRouteChangeObserver() {
        if let routeChangeNotificationObserver = self.routeChangeNotificationObserver {
            NotificationCenter.default.removeObserver(routeChangeNotificationObserver)
        }
    }
    
    // 再生準備（completionHandlerあり）
    func prepare(_ item: MusicItem, onFinish: @escaping () -> Void) throws {
        guard let path = item.assetURL else { return }
        let audioFile = try AVAudioFile(forReading: path)
        
        engine.connect(playerNode, to: eqNode, format: audioFile.processingFormat)
        engine.connect(eqNode, to: engine.mainMixerNode, format: audioFile.processingFormat)
        
        playerNode.scheduleFile(audioFile, at: nil, completionHandler: onFinish)
        
        playStatus = .prepared
    }
    
    // 再生準備（completionHandlerなし）
    func prepare(_ item: MusicItem) throws {
        try prepare(item, onFinish: {})
    }

    
    func play() throws {
        try AVAudioSession.sharedInstance().setActive(true, options: [])
        try self.engine.start()
        self.playerNode.play()
        self.playStatus = .playing
    }
    
    func stop() {
        self.playerNode.stop()
        self.engine.stop()
        self.playStatus = .stopped
    }
    
    func pause() {
        self.playerNode.pause()
        self.engine.pause()
        self.playStatus = .paused
    }
    
    func seek(to time: TimeInterval, in item: MusicItem, onFinish: @escaping () -> Void) throws {
        guard let path = item.assetURL else { return }
        let audioFile = try AVAudioFile(forReading: path)
        
        engine.stop()
        playerNode.stop()
        
        let sampleRate = audioFile.processingFormat.sampleRate
        let startFrame = AVAudioFramePosition(time * sampleRate)
        let frameCount = AVAudioFrameCount(audioFile.length - startFrame)
        
        engine.connect(playerNode, to: eqNode, format: audioFile.processingFormat)
        engine.connect(eqNode, to: engine.mainMixerNode, format: audioFile.processingFormat)
        
        playerNode.scheduleSegment(audioFile, startingFrame: startFrame, frameCount: frameCount, at: nil, completionHandler: onFinish)
        
        seekOffsetTime = time
        try engine.start()
        playerNode.play()
        playStatus = .playing
    }
    
    func seek(to time: TimeInterval, in item: MusicItem) throws {
        guard let path = item.assetURL else { return }
        let audioFile = try AVAudioFile(forReading: path)
        
        engine.stop()
        playerNode.stop()
        
        let sampleRate = audioFile.processingFormat.sampleRate
        let startFrame = AVAudioFramePosition(time * sampleRate)
        let frameCount = AVAudioFrameCount(audioFile.length - startFrame)
        
        engine.connect(playerNode, to: eqNode, format: audioFile.processingFormat)
        engine.connect(eqNode, to: engine.mainMixerNode, format: audioFile.processingFormat)
        
        playerNode.scheduleSegment(audioFile, startingFrame: startFrame, frameCount: frameCount, at: nil)
        
        seekOffsetTime = time
        try engine.start()
        playerNode.play()
        playStatus = .playing
    }

    // 再生時間取得
    func getCurrentTime() -> TimeInterval {
        if let nodeTime = playerNode.lastRenderTime,
           let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
            let elapsed = Double(playerTime.sampleTime) / playerTime.sampleRate
            return seekOffsetTime + elapsed
        }
        return seekOffsetTime
    }

    func resetSeekOffset() {
        self.seekOffsetTime = 0
    }
    
    // イコライザーバンドのゲイン更新（リアルタイム反映）
    func updateGain(band index: Int, value: Double) {
        guard eqNode.bands.indices.contains(index) else { return }
        eqNode.bands[index].gain = Float(value)
    }

}
