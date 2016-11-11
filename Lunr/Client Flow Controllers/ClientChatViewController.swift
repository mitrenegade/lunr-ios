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
    
    // this isn't being used right now but could be used for drop down alerts
    @IBOutlet weak var viewAlert: UIView!
    @IBOutlet weak var constraintAlertTop: NSLayoutConstraint!
    @IBOutlet weak var labelAlert: UILabel!
    
    func notifyForChat(user: QBUUser) {
        //guard let timestamp = lastNotificationTimestamp where NSDate().timeIntervalSinceDate(timestamp) > kMinNotificationInterval else { return }
        guard let dialogId = self.dialog.ID else { return }
        guard let currentUser = PFUser.currentUser() as? User else { return }

        let message = "You have a new client request"
        let userInfo = ["dialogId": dialogId, "pfUserId": currentUser.objectId ?? "", "chatStatus": "invited"]

        PushService().sendNotificationToQBUser(user, message: message, userInfo: userInfo) { (success, error) in
            if success {
                if TEST {
                    self.simpleAlert("Push sent!", message: "You have successfully notified \(user.fullName ?? "someone") to chat")
                }
                
                // start listening for incoming session
                self.listenForSession()
            }
            else {
                self.simpleAlert("Provider is not available", defaultMessage: nil, error: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        QBUserService.qbUUserWithId(UInt(self.dialog.recipientID), completion: { (result) in
            if let recipient = result {
                self.notifyForChat(recipient)
            }
        })
        
//        self.listenFor("video:accepted", action: #selector(openVideo), object: nil)
//        self.listenFor("video:cancelled", action: #selector(cancelChat), object: nil)
    }
    
    func openVideo() {
        /*
        let title = "Video chat was accepted"
        let message = "\(self.recipient!.fullName!) has initiated a video chat. Click start"
        self.simpleAlert(title, message: message) {
        }
        */
        if let controller = UIStoryboard(name: "CallFlow", bundle: nil).instantiateViewControllerWithIdentifier("CallViewController") as? CallViewController {
            self.navigationController?.pushViewController(controller, animated: true)
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
    
    // MARK: - Session
    func listenForSession() {
        self.listenFor(NotificationType.VideoSession.CallStateChanged.rawValue, action: #selector(handleSessionState(_:)), object: nil)
    }
    
    func handleSessionState(notification: NSNotification) {
        let userInfo = notification.userInfo
        switch SessionService.sharedInstance.state {
        case .Connected:
            self.openVideo()
            SessionService.sharedInstance.session?.acceptCall(nil)
        default:
            break
        }
    }
    
    // MARK: - Chat info
    
}
