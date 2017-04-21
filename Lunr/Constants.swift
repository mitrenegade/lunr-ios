//
//  Constants.swift
//  Lunr
//
//  Created by Bobby Ren on 8/6/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

let LOCAL_TEST = false
let TEST = true

let PARSE_APP_ID: String = "KAu5pzPvmjrFNdIeaB5zYb2la2Fs2zRi2JyuQZnA"
let PARSE_SERVER_URL_LOCAL: String = "http://localhost:1337/parse"
let PARSE_SERVER_URL = "https://lunr-server.herokuapp.com/parse"
let PARSE_CLIENT_KEY = "unused"

let QB_APP_ID: UInt = 45456
let QB_AUTH_KEY = "Ts3YVE7kHKUcYA3"
let QB_ACCOUNT_KEY = "qezMRGfSugu3WHCiT1wg"
let QB_AUTH_SECRET = "DptKZexBTDjhNt3"

let STRIPE_KEY_DEV = "pk_test_YYNWvzYJi3bTyOJi2SNK3IkE"


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
    case DialogFetched
    case DialogCancelled
    enum VideoSession: String {
        case CallStateChanged
        case VideoReady // own video has been initialized
        case VideoReceived // recipient video received
        case HungUp // recipient hung up
        
        case CallCreationFailed // not related to session but session cannot proceed because Parse failed
    }
    enum Push: String {
        case Registered
        case ReceivedInBackground
    }
    case FeedbackUpdated
    case AppReturnedFromBackground
    case ProvidersUpdated
}

let SESSION_TIMEOUT_INTERVAL: TimeInterval = 30
enum CallState: String {
    //    case NoSession // session token to QuickBlox does not exist or expired
    case Disconnected // no chatroom/webrtc joined
    //    case Joining // currently joining the chatroom
    case Waiting // in the chat but no one else is; sending call signal
    case Connected // both people are in
    case Rejected // only sent to provider if call was rejected
}

enum SortCategory : Int {
    case none = -1 // startup
    case alphabetical = 0
    case rating = 1
    case price = 2
    case favorites = 3
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
