//
//  UserService.swift
//  Lunr
//
//  Created by Bobby Ren on 9/3/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Foundation
import Parse

class UserService {
    static let sharedInstance: UserService = UserService()
    
    func queryProviders(availableOnly: Bool = false, completionHandler: ((providers:[PFUser]?) -> Void), errorHandler: ((error: NSError?)->Void)) {
        let query = PFUser.query()
        query?.whereKeyExists("type")
        query?.whereKey("type", notEqualTo: UserType.Client.rawValue)
        if availableOnly {
            query?.whereKey("available", equalTo: true)
        }
        
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