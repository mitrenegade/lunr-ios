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

public typealias EnablePushCompletionHandler = (_ success: Bool) -> Void

class PushService: NSObject {
    var enablePushCompletionHandler: EnablePushCompletionHandler?
    
    // APN
    private class func registerForAPNRemoteNotification() {
        let settings = UIUserNotificationSettings(types: [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(settings)
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private class func hasPushEnabled() -> Bool {
        if Platform.isSimulator {
            return true
        }
        
        if !UIApplication.shared.isRegisteredForRemoteNotifications {
            return false
        }
        let settings = UIApplication.shared.currentUserNotificationSettings
        if (settings?.types.contains(.alert) == true){
            return true
        }
        else {
            return false
        }
    }

    func enablePushNotifications(_ completion: @escaping ((_ success:Bool) -> Void)) {
//        if PushService.hasPushEnabled() {
//            completion(success: true)
//        }
//        else {
            self.enablePushCompletionHandler = completion
            PushService.registerForAPNRemoteNotification()
            
            self.listenFor(NotificationType.Push.Registered.rawValue, action: #selector(enableAPNPushNotificationsCompleted), object: nil)
//        }
    }
    
    @objc fileprivate func enableAPNPushNotificationsCompleted() {
        self.enablePushCompletionHandler?(PushService.hasPushEnabled())
        self.enablePushCompletionHandler = nil
        self.stopListeningFor(NotificationType.Push.Registered.rawValue)
    }

    func channelStringForPFUser(_ user: PFUser?) -> String? {
        // retrieves common channel name based on PFUser id
        guard let user = user else { return nil }
        guard let userId = user.objectId else { return nil }
        let channel = "push\(userId)"
        print("Push channel: \(channel)")
        return channel
    }
    
    func channelStringForQBUser(_ user: QBUUser?) -> String? {
        guard let channel = user?.tags[0] as? String else { return nil }
        return channel
    }
    
    // Parse push
    func registerParsePushSubscription(_ deviceToken: Data, completion: ((_ success: Bool)->Void)?) {
        guard let user = PFUser.current() else {
            completion?(false)
            return
        }
        guard let installation = PFInstallation.current() else { return }
        installation.setDeviceTokenFrom(deviceToken)
        let channel: String = self.channelStringForPFUser(user)!
        installation.addUniqueObject(channel, forKey: "channels") // subscribe to trainers channel
        
        installation.saveInBackground(block: { (success, error) in
            let channels = installation.object(forKey: "channels")
            print("installation registered for remote notifications: channel \(channels)")
            completion?(success)
        })
        
    }
    
    func unregisterParsePushSubscription() {
        guard let user = PFUser.current() else {
            return
        }
        guard let installation = PFInstallation.current() else { return }
        
        let channel: String = self.channelStringForPFUser(user)!
        installation.remove(channel, forKey: "channels") // subscribe to trainers channel
        
        installation.saveInBackground(block: { (success, error) in
            let channels = installation.object(forKey: "channels")
            print("installation registered for remote notifications: channel \(channels)")
        })
    }
    
    // Quickblox push
    func registerQBPushSubscription(_ deviceToken: Data, completion: ((_ success: Bool)->Void)?) {
        let deviceIdentifier: String = UIDevice.current.identifierForVendor!.uuidString

        let subscription: QBMSubscription! = QBMSubscription()
        subscription.notificationChannel = QBMNotificationChannel.APNS
        subscription.deviceUDID = deviceIdentifier
        subscription.deviceToken = deviceToken
        QBRequest.createSubscription(subscription, successBlock: { (response: QBResponse!, objects: [QBMSubscription]?) -> Void in
            // success
            print("Subscription created: \(objects)")
            completion?(true)
        }) { (response: QBResponse!) -> Void in
            // error
            print("Error response: \(response)")
            completion?(false)
        }
    }
    
    func sendNotificationToQBUser(_ user: QBUUser, message: String, userInfo: [String: String], completion: @escaping ((_ success:Bool, _ error:QBError?) -> Void)) {
        guard let channel = self.channelStringForQBUser(user) else { completion(false, nil); return }
        print("Channel: \(channel)")

        let push = QBMPushMessage(payload: userInfo)
        push.alertBody = message
        push.soundFile = "default"
        QBRequest.sendPush(push, toUsersWithAnyOfTheseTags: channel, successBlock: { (response, events) in
            print("Successful push \(events)")
            completion(true, nil)
        }) { (error) in
            print("Push failed with error \(error)")
            completion(false, error)
        }
    }
    
    func unregisterQBPushSubscription() {
        guard let deviceUdid = UIDevice.current.identifierForVendor?.uuidString else { return }
        
        QBRequest.unregisterSubscription(forUniqueDeviceIdentifier: deviceUdid, successBlock: { (response) in
            print("Unregistered")
            }) { (error) in
                print("error unregistering for push")
        }
    }
}
