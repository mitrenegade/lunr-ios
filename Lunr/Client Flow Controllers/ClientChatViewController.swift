//
//  ClientChatViewController.swift
//  Lunr
//
//  Created by Bobby Ren on 10/1/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//
// this keeps state and is in charge of sending a push request

import UIKit

class ClientChatViewController: ChatViewController {
    var provider: User?
    var lastNotificationTimestamp: NSDate? = NSDate()
    private let kMinNotificationInterval: NSTimeInterval = 10 // production: 1 minute?
    
    func notifyProvider(user: QBUUser) {
        //guard let timestamp = lastNotificationTimestamp where NSDate().timeIntervalSinceDate(timestamp) > kMinNotificationInterval else { return }
        guard let dialogId = self.dialog.ID else { return }
        PushService().sendChatNotificationToQBUser(user, dialogId: dialogId) { (success, error) in
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
        
        if let recipient = QBUserService.instance().usersService.usersMemoryStorage.userWithID(UInt(dialog.recipientID)) {
            self.notifyProvider(recipient)
        }
    }
}
