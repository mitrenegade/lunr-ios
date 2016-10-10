//
//  ProviderHomeViewController.swift
//  Lunr
//
//  Created by Brent Raines on 8/29/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class ProviderHomeViewController: UIViewController {
    
    // MARK: Properties
    @IBOutlet weak var providerStatusView: ProviderStatusView!
    @IBOutlet weak var onDutyToggleButton: LunrActivityButton!
    let chatSegue = "chatWithClient"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        onDutyToggleButton.cornerRadius = onDutyToggleButton.bounds.height / 2
        onDutyToggleButton.backgroundColor = UIColor.lunr_darkBlue()
        
        updateUI()
        
        if let user = PFUser.currentUser() as? User where user.available {
            PushService().enablePushNotifications({ (success) in
                print("User is available and push is enabled")
            })
        }
        
        self.listenFor("dialog:fetched", action: #selector(openChat), object: nil)
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
        if let user = PFUser.currentUser() as? User {
            let onDutyTitle = user.available ? "Go Offline" : "Go Online"
            onDutyToggleButton.setTitle(onDutyTitle, forState: .Normal)
            providerStatusView.status = user.available ? .Online : .Offline
        }
    }
        
    func openChat(notification: NSNotification) {
        guard let userInfo = notification.userInfo, dialog = userInfo["dialog"] as? QBChatDialog, incomingPFUserId = userInfo["pfUserId"] as? String else { return }
        guard QBNotificationService.sharedInstance.currentDialogID == nil else {
            print("Trying to open dialog \(dialog.ID!) but dialog \(QBNotificationService.sharedInstance.currentDialogID!) already open")
            return
        }
        
        if let chatNavigationVC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("ProviderChatNavigationController") as? UINavigationController, let chatVC = chatNavigationVC.viewControllers[0] as? ProviderChatViewController {
            chatVC.dialog = dialog
            chatVC.incomingPFUserId = incomingPFUserId
            QBNotificationService.sharedInstance.currentDialogID = dialog.ID
            self.presentViewController(chatNavigationVC, animated: true, completion: nil)
        }

    }
}
