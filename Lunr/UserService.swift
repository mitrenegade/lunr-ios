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
    static let sharedInstance: UserService = UserService()
    
    // MARK: QuickBlox
    func createQBUser(parseUserId: String, completion: ((user: QBUUser?)->Void)) {
        let user = QBUUser()
        user.login = parseUserId
        user.password = parseUserId
        QBRequest.signUp(user, successBlock: { (response, user) in
            print("results: \(user)")
            completion(user: user)
        }) { (errorResponse) in
            print("Error: \(errorResponse)")
            completion(user: nil)
        }
    }
    
    func loginQBUser(parseUserId: String, completion: ((success: Bool, error: NSError?)->Void)) {
        QBRequest.logInWithUserLogin(parseUserId, password: parseUserId, successBlock: { (response, user) in
            print("results: \(user)")
            user?.password = parseUserId // must set it again to connect to QBChat
            QBChat.instance().connectWithUser(user!) { (error) in
                if error != nil {
                    print("error: \(error)")
                    completion(success: false, error: error)
                }
                else {
                    completion(success: true, error: nil)
                }
            }
        }) { (errorResponse) in
            print("Error: \(errorResponse)")
            
            if errorResponse.status.rawValue == 401 {
                // try creating, then logging in again
                self.createQBUser(parseUserId, completion: { (user) in
                    if let _ = user {
                        self.loginQBUser(parseUserId, completion: completion)
                    }
                    else {
                        completion(success: false, error: nil)
                    }
                })
            }
            else {
                completion(success: false, error: nil)
            }
        }
    }

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
