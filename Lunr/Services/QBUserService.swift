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
import QMServices

class QBUserService: QMServicesManager {
    static let sharedInstance: QBUserService = QBUserService()
    let notificationService = QBNotificationService()
    var isRefreshingSession: Bool = false
    var currentDialogID = ""
    var isProcessingLogOut: Bool = false
    
    // MARK: Create User
    func createQBUser(parseUserId: String, completion: ((user: QBUUser?)->Void)) {
        let user = QBUUser()
        user.login = parseUserId
        user.password = parseUserId
        if let pfUser = PFUser.currentUser() as? User {
            user.fullName = pfUser.displayString
            if let channel = PushService().channelStringForPFUser(pfUser) {
                user.tags.addObject(channel)
            }
        }
        QBRequest.signUp(user, successBlock: { (response, user) in
            print("results: \(user)")
            completion(user: user)
        }) { (errorResponse) in
            print("Error: \(errorResponse)")
            completion(user: nil)
        }
    }
    
    // Mark: Login user
    func loginQBUser(parseUserId: String, completion: ((success: Bool, error: NSError?)->Void)?) {
        QBRequest.logInWithUserLogin(parseUserId, password: parseUserId, successBlock: { (response, user) in
            print("results: \(user)")
            user?.password = parseUserId // must set it again to connect to QBChat
            QBChat.instance().connectWithUser(user!) { (error) in
                if error != nil {
                    print("error: \(error)")
                    completion?(success: false, error: error)
                }
                else {
                    completion?(success: true, error: nil)
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
                        completion?(success: false, error: nil)
                    }
                })
            }
            else {
                completion?(success: false, error: nil)
            }
        }
    }
    
    
    func logoutQBUser() {
        if QBChat.instance().isConnected {
            QBChat.instance().disconnectWithCompletionBlock({ (error) in
                print("error: \(error)")
            })
        }
    }
    
    // load a QBUUser from cache by QBUserId
    class func qbUUserWithId(userId: UInt, loadFromWeb: Bool = false, completion: ((result: QBUUser?) -> Void)){
        if let user = self.instance().usersService.usersMemoryStorage.userWithID(userId) {
            completion(result: user)
        }
        if loadFromWeb {
            QBRequest.userWithID(userId, successBlock: { (response, user) in
                completion(result: user)
            }) { (response) in
                completion(result: nil)
            }
        }
        else {
            completion(result: nil)
        }
    }

    // load a QBUUser from web based on a PFUser
    class func getQBUUserFor(user: PFUser, completion: ((result: QBUUser?)->Void)) {
        guard let objectId = user.objectId else {
            completion(result: nil)
            return
        }
        self.getQBUUserForPFUserId(objectId, completion: completion)
    }
    
    class func getQBUUserForPFUserId(userId: String, completion: ((result: QBUUser?) -> Void)) {
        // TODO: can optimize to prevent extra web calls by storing qbUserId in PFUser object
        QBRequest.userWithLogin(userId, successBlock: { (response, user) in
            if let user = user {
                self.instance().usersService.usersMemoryStorage.addUser(user)
            }
            completion(result: user)
        }) { (response) in
            completion(result: nil)
        }
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
    
    // MARK: QMChatServiceDelegate
    
    override func chatService(chatService: QMChatService, didAddMessageToMemoryStorage message: QBChatMessage, forDialogID dialogID: String) {
        super.chatService(chatService, didAddMessageToMemoryStorage: message, forDialogID: dialogID)
        
        if authService.isAuthorized {
            handleNewMessage(message, dialogID: dialogID)
        }
    }
    
    func handleNewMessage(message: QBChatMessage, dialogID: String) {
//        guard currentDialogID != dialogID else { return }
//        guard message.senderID != currentUser()?.ID else { return }
//        guard let dialog = chatService.dialogsMemoryStorage.chatDialogWithID(dialogID) else { return }
//        
//        var dialogName = "New Message"
//        if dialog.type != QBChatDialogType.Private {
//            if dialog.name != nil {
//                dialogName = dialog.name!
//            }
//        } else {
//            if let user = QBUserService.instance().usersService.usersMemoryStorage.userWithID(UInt(dialog.recipientID)) {
//                dialogName = user.login!
//            }
//        }
//
//        QMMessageNotificationManager.showNotificationWithTitle(dialogName, subtitle: message.text, type: QMMessageNotificationType.Info)
    }
    
    func color(forUser user:QBUUser) -> UIColor {
        let defaultColor = UIColor.blackColor()
        let users = usersService.usersMemoryStorage.unsortedUsers()
        guard let givenUser = usersService.usersMemoryStorage.userWithID(user.ID) else {
            return defaultColor
        }
        
        let indexOfGivenUser = users.indexOf(givenUser)
        
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
