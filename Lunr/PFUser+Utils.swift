//
//  PFUser+Utils.swift
//  Lunr
//
//  Created by Bobby Ren on 5/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Foundation
import Parse

enum UserType: String {
    case Client
    case Provider
    // todo: Plumber, Electrician, Mechanic, etc?
}

extension PFUser {
    var displayString: String {
        if let name = self.username {
            return name
        }
        else if let email = self.email {
            return email
        }
        
        if self.isProvider() {
            return "a provider"
        }
        return "a customer"
    }
    
    func isProvider() -> Bool {
        if let type = self.objectForKey("type") as? String {
            return type.lowercaseString != UserType.Client.rawValue.lowercaseString
        }
        return false // users created without a provider type are clients
    }

    class func queryProviders(completionHandler: ((providers:[PFUser]?) -> Void), errorHandler: ((error: NSError?)->Void)) {
        // MARK: - load from web - should be ultimate truth
        func queryUsers() {
            let query = PFUser.query()
            query?.whereKey("type", notEqualTo: UserType.Client.rawValue)
            query?.findObjectsInBackgroundWithBlock { (results, error) -> Void in
                if let error = error {
                    errorHandler(error: error)
                    return
                }
                
                let users = results as? [PFUser]
                completionHandler(providers: users)
            }
        }
    }

    // Convenience accessors
    var name: String? {
        return self.username
    }
    
    // Client only
    
    // Provider only
    var rating: Double {
        return self.objectForKey("rating") as? Double ?? 0 // TODO: calculate rating based on all ratings?
    }
    
    var reviews: [PFObject] {
        return [] // todo: relationship with another PFObject class
    }
    
    var ratePerMin: Double {
        return self.objectForKey("ratePerMin") as? Double ?? 0
    }
    
    var available: Bool {
        return self.objectForKey("available") as? Bool ?? false
    }
    
    var skills: [String] {
        return []
    }
    
    var info: String {
        return self.objectForKey("info") as? String ?? ""
    }
}

