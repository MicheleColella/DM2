//  PathViewModel.swift


import Combine
import SwiftUI
import AVFoundation
import CoreHaptics

class PathViewModel: ObservableObject {
    @Published var scale: CGFloat = 0.2
    @Published var destinationName: String = ""
    var timer: Timer?
    var currentPathIndex = 0
    var currentPath: Path?
    var synthesizer = AVSpeechSynthesizer()
    var hapticEngine: CHHapticEngine?
    
    init() {
        prepareHapticEngine()
    }
    
    func startPath(destinationName: String) {
        guard let path = PathRepository.shared.findPath(by: destinationName) else {
            print("Nessun percorso corrispondente trovato")
            return
        }
        
        self.destinationName = path.destinationName
        currentPath = path
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            self.updateCircleSize()
        }
    }
    
    func updateCircleSize() {
        if let path = currentPath {
            scale += 0.1
            if scale > 2.5 {
                scale = 0.2
                currentPathIndex += 1
                if currentPathIndex >= path.beacons.count {
                    self.resetPath()
                }
            } else {
                playHaptic()
            }
        }
    }
    
    func resetPath() {
        currentPathIndex = 0
        scale = 0.2
        timer?.invalidate()
        timer = nil
        speakDestinationReached()
    }
    
    func speakDestinationReached() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: "Siamo arrivati alla destinazione per \(destinationName)")
        utterance.voice = AVSpeechSynthesisVoice(language: "it-IT")
        synthesizer.speak(utterance)
    }
    
    func prepareHapticEngine() {
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Errore nell'inizializzazione del motore haptico: \(error)")
        }
    }
    
    func playHaptic() {
        guard let engine = hapticEngine else { return }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(scale/2))
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(scale))
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.4)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Errore nella riproduzione del feedback haptico: \(error)")
        }
    }
}