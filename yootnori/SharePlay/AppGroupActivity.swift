//
//  AppGroupActivity.swift
//  yootnori
//
//  Created by David Lee on 9/21/25.
//

import GroupActivities

struct AppGroupActivity: GroupActivity {
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = String(localized: "Yootnori")
        metadata.type = .generic
        return metadata
    }
}
