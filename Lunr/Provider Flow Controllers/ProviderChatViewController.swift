//
//  ProviderChatViewController.swift
//  Lunr
//
//  Created by Bobby Ren on 10/2/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
