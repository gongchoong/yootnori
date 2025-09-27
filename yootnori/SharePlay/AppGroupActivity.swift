//
//  AppGroupActivity.swift
//  yootnori
//
//  Created by David Lee on 9/21/25.
//

import GroupActivities
import SharePlayMock

struct AppGroupActivity: GroupActivity {
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = String(localized: "Yootnori")
        metadata.type = .generic
        return metadata
    }
}

#if MOCK
class AppGroupActivityMock: GroupActivityMock {

    typealias ActivityType = AppGroupActivityMock.Activity

    private(set) var groupActivity: Activity

    init() {
        self.groupActivity = Activity()
    }

    struct Activity: GroupActivity {
        var metadata: GroupActivityMetadata {
            var metadata = GroupActivityMetadata()
            metadata.title = String(localized: "Yootnori")
            metadata.type = .generic
            return metadata
        }
    }
}
#endif
