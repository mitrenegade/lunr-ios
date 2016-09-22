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
    var colors = [
        UIColor(red: 0.992, green:0.510, blue:0.035, alpha:1.000),
        UIColor(red: 0.039, green:0.376, blue:1.000, alpha:1.000),
        UIColor(red: 0.984, green:0.000, blue:0.498, alpha:1.000),
        UIColor(red: 0.204, green:0.644, blue:0.251, alpha:1.000),
        UIColor(red: 0.580, green:0.012, blue:0.580, alpha:1.000),
        UIColor(red: 0.396, green:0.580, blue:0.773, alpha:1.000),
        UIColor(red: 0.765, green:0.000, blue:0.086, alpha:1.000),
        UIColor.redColor(),
        UIColor(red: 0.786, green:0.706, blue:0.000, alpha:1.000),
        UIColor(red: 0.740, green:0.624, blue:0.797, alpha:1.000)
    ]
    
    // MARK: Create User
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
    
    // MARK: Refresh user session
    func refreshSession(completion: ((success: Bool) -> Void)?) {
        // if not connected to QBChat. For example at startup
        // TODO: make this part of the Session service
        guard !isRefreshingSession else { return }
        isRefreshingSession = true
        
        guard let qbUser = QBSession.currentSession().currentUser else {
            print("No qbUser, handle this error!")
            completion?(success: false)
            return
        }
        
        guard let pfUser = PFUser.currentUser() else {
            completion?(success: false)
            return
        }
        
        qbUser.password = pfUser.objectId!
        QBChat.instance().connectWithUser(qbUser) { (error) in
            self.isRefreshingSession = false
            if error != nil {
                print("error: \(error)")
                completion?(success: false)
            }
            else {
                print("login to chat succeeded")
                completion?(success: true)
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
        
        if indexOfGivenUser < colors.count {
            return colors[indexOfGivenUser!]
        } else {
            return defaultColor
        }
    }
}
