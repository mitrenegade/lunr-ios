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
        if let controller: CallViewController = UIStoryboard(name: "CallFlow", bundle: nil).instantiateViewControllerWithIdentifier("CallViewController") as? CallViewController, let userId = incomingPFUserId {
            // BOBBY TODO
            //controller.targetPFUserId = userId
            self.navigationController?.pushViewController(controller, animated: true)
            
            // send psh notification to go to video chat
            guard let recipient = self.recipient else { return }
            self.notifyForVideo(recipient, didInitiateVideo: true)
        }
    }
    
    // MARK: Push notifications
    func notifyForVideo(user: QBUUser, didInitiateVideo: Bool) {
        //guard let timestamp = lastNotificationTimestamp where NSDate().timeIntervalSinceDate(timestamp) > kMinNotificationInterval else { return }
        guard let currentUser = PFUser.currentUser() as? User else { return }
        
        let name = currentUser.displayString
        
        let status = didInitiateVideo ? "started": "cancelled"
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
