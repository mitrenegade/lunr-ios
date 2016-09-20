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
    @IBOutlet weak var chatButton: LunrActivityButton!
    @IBOutlet weak var onDutyToggleButton: LunrActivityButton!
    let chatSegue = "chatWithClient"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        onDutyToggleButton.cornerRadius = onDutyToggleButton.bounds.height / 2
        updateUI()
    }
    
    @IBAction func chatWithClient(sender: AnyObject) {
        chatButton.busy = true
        PFUser.query()?.getObjectInBackgroundWithId("aECYB3GJL4") { user, error in
            guard let user = user as? PFUser where error == nil else { return }
            QBUserService.getQBUUserFor(user) { user in
                guard let user = user else { return }
                QBUserService.instance().chatService.createPrivateChatDialogWithOpponent(user) { [weak self] response, dialog in
                    self?.chatButton.busy = false
                    let chatVC = ChatViewController()
                    chatVC.dialog = dialog
                    self?.presentViewController(chatVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func toggleOnDuty(sender: AnyObject) {
        if let user = PFUser.currentUser() as? User {
            onDutyToggleButton.busy = true
            user.available = !user.available
            user.saveInBackgroundWithBlock { [weak self] (success, error) in
                self?.onDutyToggleButton.busy = false
                if success {
                    self?.updateUI()
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
        }
    }
}
