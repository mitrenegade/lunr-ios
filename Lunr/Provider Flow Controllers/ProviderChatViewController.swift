//
//  ProviderChatViewController.swift
//  Lunr
//
//  Created by Bobby Ren on 10/2/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class ProviderChatViewController: ChatViewController {

    var incomingPFUserId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func updateTitle() {
        super.updateTitle()
        
        if self.recipient == nil {
            self.loadUser()
        }
    }
    
    func loadUser() {
        // load user
        guard let pfUserId = incomingPFUserId else { return }
        QBUserService.getQBUUserForPFUserId(pfUserId, completion: { (result) in
            if let _ = result {
                self.updateTitle()
            }
        })
    }

    @IBAction override func dismiss(sender: AnyObject?) {
        dismissViewControllerAnimated(true) { 
            // send push notification to cancel
            guard let recipient = self.recipient else { return }
            QBNotificationService.sharedInstance.clearDialog()
            self.notifyForVideo(recipient, didInitiateVideo: false)
        }
    }

    @IBAction func startCall(sender: AnyObject) {
        guard let recipient = self.recipient else { return }
        print("Starting call service")
        SessionService.sharedInstance.startCall(recipient.ID)
        // start listening for incoming session
        self.listenForAcceptSession()
    }
    
    func openVideo() {
        if let controller: CallViewController = UIStoryboard(name: "CallFlow", bundle: nil).instantiateViewControllerWithIdentifier("CallViewController") as? CallViewController {
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    // MARK: Push notifications
    func notifyForVideo(user: QBUUser, didInitiateVideo: Bool) {
        // actually notifyForRejectVideo - do not create a call state but send a push
        guard let currentUser = PFUser.currentUser() as? User else { return }
        
        let name = currentUser.displayString
        
        if !didInitiateVideo {
            let status = "cancelled"
            let message = "\(name) has \(status) video chat"
            let userInfo = [QBMPushMessageSoundKey: "default", QBMPushMessageAlertKey: message, "videoChatStatus": status, "dialogId": QBNotificationService.sharedInstance.currentDialogID ?? ""]
            
            PushService().sendNotificationToQBUser(user, userInfo: userInfo) { (success, error) in
                if success {
                    self.simpleAlert("Push sent!", message: "You have successfully \(status) video chat with \(user.fullName ?? "someone")")
                }
                else {
                    self.simpleAlert("Could not send push", defaultMessage: nil, error: nil)
                }
            }
        }
    }

    // MARK: Session
    func listenForAcceptSession() {
        self.listenFor(NotificationType.VideoSession.CallStateChanged.rawValue, action: #selector(handleSessionState(_:)), object: nil)
    }

    func handleSessionState(notification: NSNotification) {
        let userInfo = notification.userInfo
        switch SessionService.sharedInstance.state {
        case .Connected:
            print("incoming call")
            self.openVideo()
        default:
            break
        }
    }

}
