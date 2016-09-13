//
//  Constants.swift
//  Lunr
//
//  Created by Bobby Ren on 8/6/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

enum Segue {
    enum Login: String {
        case GoToLogin
        case GoToSignup
    }
    enum Call: String {
        case GoToCallUser
    }
}

enum NotificationType: String {
    case LogoutSuccess = "logout:success"
    case LoginSuccess = "login:success"
}

enum FilteredBy: String {
    case Alphabetical
    case Rating
    case Cost
    case Favorite
}