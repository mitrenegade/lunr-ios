//
//  Constants.swift
//  Lunr
//
//  Created by Bobby Ren on 8/6/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

enum UserDefaultsKeys: String {
    case SortCategory = "defaults:sortCategory"
}

enum Segue {
    enum Login: String {
        case GoToLogin
        case GoToSignup
    }
    enum Call: String {
        case GoToCallUser
        case GoToFeedback
    }
}

enum NotificationType: String {
    case LogoutSuccess
    case LoginSuccess
    enum VideoSession: String {
        case CallStateChanged
        case VideoReady // own video has been initialized
        case StreamInitialized // after startCall, successfully connected to stream
        case VideoReceived // recipient video received
        case HungUp // recipient hung up
        
        case CallCreationFailed // not related to session but session cannot proceed because Parse failed
    }
    case PushRegistered
}

enum SortCategory : Int {
    case None = -1 // startup
    case Alphabetical = 0
    case Rating = 1
    case Price = 2
    case Favorites = 3
}

struct Platform {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
            isSim = true
        #endif
        return isSim
    }()
}
