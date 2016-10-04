//
//  PushService.swift
//  Lunr
//
//  Created by Bobby Ren on 9/26/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import Quickblox
import QMServices

class PushService: NSObject {
    class func registerForRemoteNotification() {
        let settings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    func enablePushNotifications(completion: ((success:Bool) -> Void)) {
        let userId = PFUser.currentUser()!.objectId! // TODO: use optional checks
        if !QBChat.instance().isConnected {
            QBUserService.sharedInstance.loginQBUser(userId, completion: { (success, error) in
                if !success {
                    completion(success: false)
                }
                else {
                    self.enablePushNotifications(completion)
                }
            })
            return
        }
        else {
            // TODO: check if it is already enabled, and show error message to go to settings
            PushService.registerForRemoteNotification()
            completion(success: true)
        }
    }

    func channelStringForPFUser(user: PFUser?) -> String? {
        // retrieves common channel name based on PFUser id
        guard let user = user else { return nil }
        guard let userId = user.objectId else { return nil }
        let channel = "push\(userId)"
        return channel
    }
    
    func channelStringForQBUser(user: QBUUser?) -> String? {
        guard let channel = user?.tags[0] as? String else { return nil }
        return channel
    }
    
    func sendNotificationToPFUser(user: PFUser, completion: ((success:Bool, error:QBError?) -> Void)) {
        guard let channel = self.channelStringForPFUser(user) else { return }
        print("Channel: \(channel)")
        
        QBRequest.sendPushWithText("Test", toUsersWithAnyOfTheseTags: channel, successBlock: { (response, events) in
            print("Successful push \(events)")
            completion(success: true, error: nil)
            }) { (error) in
                print("Push failed with error \(error)")
                completion(success: false, error: error)
        }
    }
    
    func sendNotificationToQBUser(user: QBUUser, userInfo: [String: String], completion: ((success:Bool, error:QBError?) -> Void)) {
        guard let channel = self.channelStringForQBUser(user) else { completion(success: false, error: nil); return }
        print("Channel: \(channel)")

        let push = QBMPushMessage(payload: userInfo)
        QBRequest.sendPush(push, toUsersWithAnyOfTheseTags: channel, successBlock: { (response, events) in
            print("Successful push \(events)")
            completion(success: true, error: nil)
        }) { (error) in
            print("Push failed with error \(error)")
            completion(success: false, error: error)
        }
    }
}
