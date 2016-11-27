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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class QBUserService {
    static let sharedInstance: QBUserService = QBUserService()
    
    var isProcessingLogOut: Bool = false
    var isRefreshingSession: Bool = false
    
    // MARK: Create User
    func createQBUser(_ parseUserId: String, completion: @escaping ((_ user: QBUUser?)->Void)) {
        let user = QBUUser()
        user.login = parseUserId
        user.password = parseUserId
        if let pfUser = PFUser.current() as? User {
            user.fullName = pfUser.displayString
            if let channel = PushService().channelStringForPFUser(pfUser) {
                user.tags.add(channel)
            }
        }
        QBRequest.signUp(user, successBlock: { (response, user) in
            print("results: \(user)")
            completion(user)
        }) { (errorResponse) in
            print("Error: \(errorResponse)")
            completion(nil)
        }
    }
    
    // Mark: Login user
    func loginQBUser(_ parseUserId: String, completion: ((_ success: Bool, _ error: NSError?)->Void)?) {
        QBRequest.logIn(withUserLogin: parseUserId, password: parseUserId, successBlock: { (response, user) in
            print("results: \(user)")
            user?.password = parseUserId // must set it again to connect to QBChat
            QBChat.instance().connect(with: user!) { (error) in
                if error != nil {
                    print("error: \(error)")
                    completion?(false, error as NSError?)
                }
                else {
                    completion?(true, nil)
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
                        completion?(false, nil)
                    }
                })
            }
            else {
                completion?(false, nil)
            }
        }
    }
    
    // MARK: Refresh user session
    func refreshUserSession(_ completion: ((_ success: Bool) -> Void)?) {
        // if not connected to QBChat. For example at startup
        // TODO: make this part of the Session service
        guard !isRefreshingSession else { return }
        isRefreshingSession = true
        
        guard let pfUser = PFUser.current(), let userId = pfUser.objectId else {
            self.isRefreshingSession = false
            completion?(false)
            return
        }
        
        guard let qbUser = QBSession.current().currentUser else {
            self.loginQBUser(userId, completion: { (success, error) in
                if (success) {
                    self.isRefreshingSession = false
                    self.refreshUserSession(completion)
                }
                else {
                    print("No qbUser, handle this error!")
                    self.isRefreshingSession = false
                    completion?(false)
                }
            })
            return
        }
        
        if QBChat.instance().isConnected {
            self.isRefreshingSession = false
            completion?(true)
            return
        }
        
        qbUser.password = pfUser.objectId!
        QBChat.instance().connect(with: qbUser) { (error) in
            self.isRefreshingSession = false
            if let error = error {
                print("error: \(error)")
                if error.code == 401 {
                    // invalid user (quickblox user got deleted or does not exist)
                    self.loginQBUser(userId, completion: { (success, error) in
                        completion?(success)
                    })
                }
                else {
                    completion?(false)
                }
            }
            else {
                print("login to chat succeeded")
                completion?(true)
            }
        }
    }

    func logoutQBUser() {
        if QBChat.instance().isConnected {
            QBChat.instance().disconnect(completionBlock: { (error) in
                print("error: \(error)")
            })
        }
    }
    
    // load a QBUUser from cache by QBUserId
    class func qbUUserWithId(_ userId: UInt, loadFromWeb: Bool = false, completion: @escaping ((_ result: QBUUser?) -> Void)){
        if let user = self.cachedUserWithId(userId) {
            completion(user)
            return
        }
        if loadFromWeb {
            QBRequest.user(withID: userId, successBlock: { (response, user) in
                completion(user)
            }) { (response) in
                completion(nil)
            }
        }
        else {
            completion(nil)
        }
    }
    
    class func cachedUserWithId(_ userId: UInt) -> QBUUser? {
        return SessionService.sharedInstance.usersService.usersMemoryStorage.user(withID: userId)
    }

    // load a QBUUser from web based on a PFUser
    class func getQBUUserFor(_ user: PFUser, completion: @escaping ((_ result: QBUUser?)->Void)) {
        guard let objectId = user.objectId else {
            completion(nil)
            return
        }
        self.getQBUUserForPFUserId(objectId, completion: completion)
    }
    
    class func getQBUUserForPFUserId(_ userId: String, completion: @escaping ((_ result: QBUUser?) -> Void)) {
        // TODO: can optimize to prevent extra web calls by storing qbUserId in PFUser object
        QBRequest.user(withLogin: userId, successBlock: { (response, user) in
            if let user = user {
                SessionService.sharedInstance.usersService.usersMemoryStorage.add(user)
            }
            completion(user)
        }) { (response) in
            completion(nil)
        }
    }
    
    // Loads all users from quickblox (paged)
    fileprivate class func loadUsersWithCompletion(_ completion: @escaping ((_ results: [QBUUser]?)->Void)) {
        let responsePage: QBGeneralResponsePage = QBGeneralResponsePage(currentPage: 0, perPage: 100)
        QBRequest.users(for: responsePage, successBlock: { (response, responsePage, users) in
            print("users received: \(users)")
            completion(users)
            
        }) { (response) in
            print("error with users response: \(response.error)")
        }
    }
        
    func color(forUser user:QBUUser) -> UIColor {
        let defaultColor = UIColor.black
        let users = SessionService.sharedInstance.usersService.usersMemoryStorage.unsortedUsers()
        guard let givenUser = SessionService.sharedInstance.usersService.usersMemoryStorage.user(withID: user.id) else {
            return defaultColor
        }
        
        let indexOfGivenUser = users.index(of: givenUser)
        
        if indexOfGivenUser < UIColor.qbChatColors.count {
            return UIColor.qbChatColors[indexOfGivenUser!]
        } else {
            return defaultColor
        }
    }
    
    // MARK: Push
    /*
    func updateUserPushTag() {
        // this updates QBUUser information for a provider. Update tags as well as display name
        guard let qbUser = QBSession.currentSession().currentUser else {
            return
        }
        guard let channel = qbUser.login else { return }
        let params = QBUpdateUserParameters()
        params.tags = ["push\(channel)"]
        if let pfUser = PFUser.currentUser() as? User {
            params.fullName = pfUser.displayString
        }
        QBRequest.updateCurrentUser(params, successBlock: { (response, user) in
            print("Success! \(user)")
            }) { (response) in
                print("Error response: \(response)")
        }
    }

    func updateUserFullName() {
        // adds fullName to a qbUser when they create an account
        guard let qbUser = QBSession.currentSession().currentUser else {
            return
        }
        guard let pfUser = PFUser.currentUser() as? User else { return }
        let params = QBUpdateUserParameters()
        params.fullName = pfUser.displayString
        
        QBRequest.updateCurrentUser(params, successBlock: { (response, user) in
            print("Success! \(user)")
        }) { (response) in
            print("Error response: \(response)")
        }
    }
    */
}
