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
    case Plumber
    case Electrician
    case Handyman
}

class User: PFUser {
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var type: String?
    @NSManaged var callHistory: [Call]?
    
    // Client
    @NSManaged var payment: PaymentMethod?

    // Provider
    @NSManaged var rating : Double
    @NSManaged var reviews : [Review]?
    @NSManaged var ratePerMin : Double
    @NSManaged var available : Bool
    @NSManaged var skills : [String]?
    @NSManaged var info : String
    
    override init () {
        super.init()
    }
    
    // This shouldn't be used - only for testing
    init(firstName: String, lastName: String, type: UserType, rating: Double, ratePerMin : Double, skills: [String], info: String, available: Bool) {
        super.init()
        
        self.firstName = firstName
        self.lastName = lastName
        self.type = type.rawValue.lowercaseString
        self.rating = rating
        self.ratePerMin = ratePerMin
        self.skills = skills
        self.info = info
        self.available = available
    }

}

// MARK: Extension for user convenience methods
extension User {
    var displayString: String {
        get {
            if let first = self.firstName, last = self.lastName {
                return "\(first) \(last)"
            }
            return self.firstName ?? self.lastName ?? self.email ?? (self.isProvider ? "a provider" : "a client")
        }
    }
    
    var userType: UserType {
        get {
            let types: [UserType] = [.Plumber, .Electrician, .Handyman, .Client]
            for type in types {
                if type.rawValue.lowercaseString == self.type?.lowercaseString {
                    return type
                }
            }
            
            return .Client
        }
    }
    
    var isProvider: Bool {
        return self.userType == .Plumber || self.userType == .Electrician || self.userType == .Handyman
    }
}
