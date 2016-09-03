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
        
        // todo
    }
    
    // This shouldn't be used - only for testing
    init(firstName: String, lastName: String, rating: Double, reviews: [Review], ratePerMin : Double, skills: [String], info: String, available: Bool) {
        super.init()
        
        self.firstName = firstName
        self.lastName = lastName
        self.rating = rating
        self.reviews = reviews
        self.ratePerMin = ratePerMin
        self.skills = skills
        self.info = info
        self.available = available
    }

}

// MARK: Extension for user convenience methods
extension User {
    var name: String? {
        if let first = self.firstName, last = self.lastName {
            return "\(first) \(last)"
        }
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
