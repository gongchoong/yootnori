//
//  SoundEffect.swift
//  yootnori
//
//  Created by davidlee on 5/23/26.
//

import Foundation

struct SoundEffect {
    let fileName: String
    let fileExtension: String
}

extension SoundEffect {

    static let jump = SoundEffect(
        fileName: "jump",
        fileExtension: "wav"
    )

    static let yoot_1 = SoundEffect(
        fileName: "yoot_1",
        fileExtension: "m4a"
    )

    static let yoot_2 = SoundEffect(
        fileName: "yoot_2",
        fileExtension: "m4a"
    )

    static let yoot_3 = SoundEffect(
        fileName: "yoot_3",
        fileExtension: "m4a"
    )

    static let yoot_4 = SoundEffect(
        fileName: "yoot_4",
        fileExtension: "m4a"
    )

    static let score = SoundEffect(
        fileName: "score",
        fileExtension: "mp3"
    )

    static let capture = SoundEffect(
        fileName: "capture",
        fileExtension: "m4a"
    )

    static let piggyback = SoundEffect(
        fileName: "piggyback",
        fileExtension: "m4a"
    )
}
