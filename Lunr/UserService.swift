//
//  UserService.swift
//  Lunr
//
//  Created by Bobby Ren on 8/13/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//
// Manages loading of PFUsers and their related QBUUsers

import UIKit
import Parse
import Quickblox

class UserService: NSObject {

    // TODO: load QBUUser for given user based on pfObjectId
    class func getQBUUserFor(user: PFUser, completion: ((result: QBUUser?)->Void)) {
        completion(result: nil)
    }
    
    // Loads all users from quickblox for now
    class func loadUsersWithCompletion(completion: ((results: [QBUUser]?)->Void)) {
        let responsePage: QBGeneralResponsePage = QBGeneralResponsePage(currentPage: 0, perPage: 100)
        QBRequest.usersForPage(responsePage, successBlock: { (response, responsePage, users) in
            print("users received: \(users)")
            completion(results: users)
            
        }) { (response) in
            print("error with users response: \(response.error)")
        }
    }
}
