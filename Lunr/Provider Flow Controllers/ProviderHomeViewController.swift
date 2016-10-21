//
//  ProviderHomeViewController.swift
//  Lunr
//
//  Created by Brent Raines on 8/29/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class ProviderHomeViewController: UIViewController, ProviderStatusViewDelegate {
    
    // MARK: Properties
    @IBOutlet weak var providerStatusView: ProviderStatusView!
    @IBOutlet weak var onDutyToggleButton: LunrRoundActivityButton!
    let chatSegue = "chatWithClient"

    var dialog: QBChatDialog?
    var incomingPFUserId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onDutyToggleButton.backgroundColor = UIColor.lunr_darkBlue()
        
        providerStatusView.delegate = self
        
        updateUI()
        
        if let user = PFUser.currentUser() as? User where user.available {
            PushService().enablePushNotifications({ (success) in
                print("User is available and push is enabled")
            })
        }
        
        self.listenFor("dialog:fetched", action: #selector(handleIncomingChatRequest(_:)), object: nil)
    }
    
    @IBAction func toggleOnDuty(sender: AnyObject) {
        if let user = PFUser.currentUser() as? User {
            onDutyToggleButton.busy = true
            user.available = !user.available
            user.saveInBackgroundWithBlock { [weak self] (success, error) in
                self?.onDutyToggleButton.busy = false
                if success {
                    self?.updateUI()
                    if user.available {
                        PushService().enablePushNotifications({ (success) in
                            if !success {
                                self?.simpleAlert("There was an error enabling push", defaultMessage: nil, error: error, completion: nil)
                            }
                        })
                    }
                } else if let error = error {
                    self?.simpleAlert("There was an error", defaultMessage: nil, error: error, completion: nil)
                }
            }
        }
    }
    
    private func updateUI() {
        // does not handle .NewRequest because updateUI is for online/offline and waiting
        if let user = PFUser.currentUser() as? User {
            let onDutyTitle = user.available ? "Go Offline" : "Go Online"
            onDutyToggleButton.setTitle(onDutyTitle, forState: .Normal)
            providerStatusView.status = user.available ? .Online : .Offline
        }
        
        // clear locally stored dialog and userIds that were saved from previous notifications
        self.dialog = nil
        self.incomingPFUserId = nil
    }
    
    func handleIncomingChatRequest(notification: NSNotification) {
        guard let userInfo = notification.userInfo, dialog = userInfo["dialog"] as? QBChatDialog, incomingPFUserId = userInfo["pfUserId"] as? String else { return }
        guard QBNotificationService.sharedInstance.currentDialogID == nil else {
            print("Trying to open dialog \(dialog.ID!) but dialog \(QBNotificationService.sharedInstance.currentDialogID!) already open")
            return
        }
        
        QBUserService.getQBUUserForPFUserId(incomingPFUserId) { [weak self] (result) in
            if let user = result {
                self?.incomingPFUserId = incomingPFUserId
                self?.dialog = dialog
                self?.providerStatusView.status = .NewRequest(user)
            }
            else {
                print("Could not load incoming user! Ignore it (?)")
            }
        }
    }
    
    func didClickReply() {
        if let chatNavigationVC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("ProviderChatNavigationController") as? UINavigationController, let chatVC = chatNavigationVC.viewControllers[0] as? ProviderChatViewController {
            guard let dialog = self.dialog, userId = self.incomingPFUserId else { return }
            chatVC.dialog = dialog
            chatVC.incomingPFUserId = userId
            QBNotificationService.sharedInstance.currentDialogID = dialog.ID
            
            self.presentViewController(chatNavigationVC, animated: true, completion: { 
                // reset to original state
                self.updateUI()
            })
        }

    }
    
    /* TODO:
     - dismiss a call request. (other than go offline)
    */
}
