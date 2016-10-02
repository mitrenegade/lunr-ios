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
        if let recipient = QBUserService.instance().usersService.usersMemoryStorage.userWithID(UInt(dialog.recipientID)) {
            title = recipient.fullName
        }
        else {
            self.loadUser()
        }
    }
    
    func loadUser() {
        // load user
        guard let pfUserId = incomingPFUserId else { return }
        QBUserService.getQBUUserForPFUserId(pfUserId, completion: { (result) in
            if let recipient = result {
                QBUserService.instance().usersService.usersMemoryStorage.addUser(recipient)
                self.updateTitle()
            }
        })
    }

    @IBAction override func dismiss(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
        
        // TODO: send push notification to cancel
    }

    @IBAction func startCall(sender: AnyObject) {
        if let controller: CallViewController = UIStoryboard(name: "CallFlow", bundle: nil).instantiateViewControllerWithIdentifier("CallViewController") as? CallViewController, let userId = incomingPFUserId {
            controller.targetPFUserId = userId
            self.navigationController?.pushViewController(controller, animated: true)
            
            // TODO: send psh notification to go to video chat
        }
    }
}
