//
//  User.swift
//  Lunr
//
//  Created by Bobby Ren on 9/2/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

enum UserType: String {
    case Client
    case Provider
    // todo: Plumber, Electrician, Mechanic, etc?
}

class User: PFUser {
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var type: String?
    @NSManaged var callHistory: [Call]?
}

// MARK: Extension for user convenience methods
extension User {
    var name: String? {
        return self.firstName ?? self.lastName ?? self.username
    }
    
    var displayString: String {
        get {
            return self.name ?? self.email ?? (self.userType == .Provider ? "a provider" : "a client")
        }
    }
    
    var userType: UserType {
        get {
            let types: [UserType] = [.Provider, .Client]
            for type in types {
                if type.rawValue.lowercaseString == self.type?.lowercaseString {
                    return type
                }
            }
            
            return .Client
        }
    }
}
