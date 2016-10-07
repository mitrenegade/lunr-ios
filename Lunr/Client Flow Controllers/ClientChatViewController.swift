//
//  ClientChatViewController.swift
//  Lunr
//
//  Created by Bobby Ren on 10/1/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//
// this keeps state and is in charge of sending a push request

import UIKit
import Parse

class ClientChatViewController: ChatViewController {
    var providerId: String?
    var lastNotificationTimestamp: NSDate? = NSDate()
    private let kMinNotificationInterval: NSTimeInterval = 10 // production: 1 minute?
    
    func notifyForChat(user: QBUUser) {
        //guard let timestamp = lastNotificationTimestamp where NSDate().timeIntervalSinceDate(timestamp) > kMinNotificationInterval else { return }
        guard let dialogId = self.dialog.ID else { return }
        guard let currentUser = PFUser.currentUser() as? User else { return }

        let message = "You have a new client request"
        let userInfo = [QBMPushMessageSoundKey: "default", QBMPushMessageAlertKey: message, "dialogId": dialogId, "pfUserId": currentUser.objectId ?? "", "chatStatus": "invited"]

        PushService().sendNotificationToQBUser(user, userInfo: userInfo) { (success, error) in
            if success {
                self.simpleAlert("Push sent!", message: "You have successfully notified \(user.fullName ?? "someone") to chat")
            }
            else {
                self.simpleAlert("Could not send push", defaultMessage: nil, error: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PushService().enablePushNotifications({ (success) in
            if !success {
                self.simpleAlert("There was an error enabling push", defaultMessage: nil, error: nil, completion: nil)
            }
            else {
                if let recipient = QBUserService.qbUUserWithId(self.dialog.recipientID) {
                    self.notifyForChat(recipient)
                }
            }
        })
        
        self.listenFor("video:accepted", action: #selector(openVideo), object: nil)
        self.listenFor("video:cancelled", action: #selector(cancelChat), object: nil)
    }
    
    func openVideo() {
        let title = "Video chat was accepted"
        let message = "\(self.recipient!.fullName!) has initiated a video chat. Click start"
        self.simpleAlert(title, message: message) {
            if let controller = UIStoryboard(name: "CallFlow", bundle: nil).instantiateViewControllerWithIdentifier("CallViewController") as? CallViewController {
                controller.targetPFUserId = self.providerId
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    func cancelChat() {
        let title = "Video chat was declined"
        let message = "\(self.recipient!.fullName!) has cancelled the video chat."
        self.simpleAlert(title, message: message) {
            self.dismiss(nil)
            QBNotificationService.sharedInstance.clearDialog()
        }
    }
}
