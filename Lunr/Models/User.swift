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
    @NSManaged var favorites: [String]

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
    
    // MARK: Favorites
    // Client only
    func toggleFavorite(provider: User, completion: ((success: Bool)->Void)?) {
        guard let objectId = provider.objectId else { completion?(success: false); return }
        if !self.favorites.contains(objectId) {
            self.favorites.append(objectId)
        }
        else {
            self.favorites.removeAtIndex(self.favorites.indexOf(objectId)!)
        }
        
        self.saveInBackgroundWithBlock { (success, error) in
            completion?(success: success)
        }
    }
    
    // Provider only
    func isFavoriteOf(client: User) -> Bool {
        guard let objectId = self.objectId else { return false }
        return client.favorites.contains(objectId)
    }
}

extension String {
    func isValidEmail() -> Bool {
        // http://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
        let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(self)
    }
}
