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
        case GoToFeedback = "feedbackSegue"
    }
}

enum NotificationType: String {
    case LogoutSuccess = "logout:success"
    case LoginSuccess = "login:success"
}

enum SortCategory : Int {
    case None = -1 // startup
    case Alphabetical = 0
    case Rating = 1
    case Price = 2
    case Favorites = 3
}