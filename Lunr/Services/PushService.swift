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

public typealias EnablePushCompletionHandler = (success: Bool) -> Void

class PushService: NSObject {
    var enablePushCompletionHandler: EnablePushCompletionHandler?
    
    // APN
    class func registerForAPNRemoteNotification() {
        let settings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    class func hasPushEnabled() -> Bool {
        if Platform.isSimulator {
            return true
        }
        
        if !UIApplication.sharedApplication().isRegisteredForRemoteNotifications() {
            return false
        }
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        if (settings?.types.contains(.Alert) == true){
            return true
        }
        else {
            return false
        }
    }

    func enablePushNotifications(completion: ((success:Bool) -> Void)) {
//        if PushService.hasPushEnabled() {
//            completion(success: true)
//        }
//        else {
            self.enablePushCompletionHandler = completion
            PushService.registerForAPNRemoteNotification()
            
            self.listenFor(.PushRegistered, action: #selector(enableAPNPushNotificationsCompleted), object: nil)
//        }
    }
    
    @objc private func enableAPNPushNotificationsCompleted() {
        self.enablePushCompletionHandler?(success: PushService.hasPushEnabled())
        self.enablePushCompletionHandler = nil
        self.stopListeningFor(.PushRegistered)
    }

    func channelStringForPFUser(user: PFUser?) -> String? {
        // retrieves common channel name based on PFUser id
        guard let user = user else { return nil }
        guard let userId = user.objectId else { return nil }
        let channel = "push\(userId)"
        print("Push channel: \(channel)")
        return channel
    }
    
    func channelStringForQBUser(user: QBUUser?) -> String? {
        guard let channel = user?.tags[0] as? String else { return nil }
        return channel
    }
    
    // Quickblox push
    func registerQBPushSubscription(deviceToken: NSData, completion: ((success: Bool)->Void)?) {
        let deviceIdentifier: String = UIDevice.currentDevice().identifierForVendor!.UUIDString

        let subscription: QBMSubscription! = QBMSubscription()
        subscription.notificationChannel = QBMNotificationChannel.APNS
        subscription.deviceUDID = deviceIdentifier
        subscription.deviceToken = deviceToken
        QBRequest.createSubscription(subscription, successBlock: { (response: QBResponse!, objects: [QBMSubscription]?) -> Void in
            // success
            print("Subscription created: \(objects)")
            completion?(success: true)
        }) { (response: QBResponse!) -> Void in
            // error
            print("Error response: \(response)")
            completion?(success: false)
        }
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
