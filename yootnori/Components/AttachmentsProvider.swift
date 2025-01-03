//
//  AttachmentsProvider.swift
//  yootnori
//
//  Created by David Lee on 11/27/24.
//

import SwiftUI
import Observation

@Observable
final class AttachmentsProvider {

    var attachments: [ObjectIdentifier: AnyView] = [:]

    var sortedTagViewPairs: [(tag: ObjectIdentifier, view: AnyView)] {
        attachments.map { key, value in
            (tag: key, view: value)
        }.sorted { $0.tag < $1.tag }
    }
}
