//
//  SoundEffectManager.swift
//  yootnori
//
//  Created by davidlee on 5/23/26.
//

import AVFoundation

final class SoundEffectManager {

    static let shared = SoundEffectManager()

    private var players: [AVAudioPlayer] = []

    func playSound(
        _ soundEffect: SoundEffect
    ) {
        guard let url = Bundle.main.url(
            forResource: soundEffect.fileName,
            withExtension: soundEffect.fileExtension
        ) else {
            print("Missing sound file")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)

            player.prepareToPlay()
            player.volume = 1.0
            player.play()

            // Keep strong reference while playing
            players.append(player)

            // Cleanup finished players
            players.removeAll { !$0.isPlaying }

        } catch {
            print("Audio playback failed:", error)
        }
    }
}
