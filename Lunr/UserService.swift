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

    // load a QBUUser based on a PFUser
    class func getQBUUserFor(user: PFUser, completion: ((result: QBUUser?)->Void)) {
        guard let objectId = user.objectId else {
            completion(result: nil)
            return
        }

        QBRequest.userWithLogin(objectId, successBlock: { (response, user) in
                completion(result: user)
            }) { (response) in
                completion(result: nil)
        }

        /*
        self.loadUsersWithCompletion { (results) in
            guard let users = results, objectId = user.objectId else {
                completion(result: nil)
                return
            }

            let matches = users.filter { $0.login == objectId };
            completion(result: matches.first)
        }
        */
    }
    
    // Loads all users from quickblox (paged)
    private class func loadUsersWithCompletion(completion: ((results: [QBUUser]?)->Void)) {
        let responsePage: QBGeneralResponsePage = QBGeneralResponsePage(currentPage: 0, perPage: 100)
        QBRequest.usersForPage(responsePage, successBlock: { (response, responsePage, users) in
            print("users received: \(users)")
            completion(results: users)
            
        }) { (response) in
            print("error with users response: \(response.error)")
        }
    }
}
