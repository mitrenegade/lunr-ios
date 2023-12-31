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
    var provider: User?
    var lastNotificationTimestamp: Date? = Date()
    fileprivate let kMinNotificationInterval: TimeInterval = 10 // production: 1 minute?
    
    var conversation: Conversation?
    
    // this isn't being used right now but could be used for drop down alerts
    @IBOutlet weak var viewAlert: UIView!
    @IBOutlet weak var constraintAlertTop: NSLayoutConstraint!
    @IBOutlet weak var labelAlert: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        QBUserService.qbUUserWithId(UInt(self.dialog.recipientID), completion: { (result) in
            if let recipient = result {
                // start listening for incoming session
                self.listenForSession()
            }
        })
        self.listenFor("video:accepted", action: #selector(openVideo), object: nil)
//        self.listenFor("video:cancelled", action: #selector(cancelChat), object: nil)
    }
    
    func promptForVideo() {
        let title = "\(self.recipient!.fullName!) has initiated a video chat."
        var message = "Click Accept to join."
        if let provider = self.provider {
            let currencyFormatter = NumberFormatter()
            currencyFormatter.usesGroupingSeparator = true
            currencyFormatter.numberStyle = NumberFormatter.Style.currency
            currencyFormatter.locale = Locale.current
            let rateString = currencyFormatter.string(from: NSNumber(value: provider.ratePerMin))!
            message = "This call will cost \(rateString) per minute. \(message)"
        }
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
            SessionService.sharedInstance.session?.rejectCall(nil)
            self.dismiss(nil)
        }

        let openAction = UIAlertAction(title: "Accept", style: .destructive) { action in
            self.openVideo()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(openAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func openVideo() {
        if let controller = UIStoryboard(name: "CallFlow", bundle: nil).instantiateViewController(withIdentifier: "CallViewController") as? CallViewController {
            self.navigationController?.pushViewController(controller, animated: true)
            SessionService.sharedInstance.session?.acceptCall(nil)
            
            self.endConversation()
        }
    }
    
    // MARK: - Session
    func listenForSession() {
        self.listenFor(NotificationType.VideoSession.CallStateChanged.rawValue, action: #selector(handleSessionState(_:)), object: nil)
    }
    
    func handleSessionState(_ notification: Notification) {
        let userInfo = notification.userInfo
        switch SessionService.sharedInstance.state {
        case .Connected:
            self.promptForVideo()
        default:
            break
        }
    }

    @IBAction override func dismiss(_ sender: AnyObject?) {
        self.endConversation()
        super.dismiss(sender)
    }
    
    func endConversation() {
        conversation?.status = ConversationStatus.done.rawValue
        conversation?.saveInBackground()
    }
    
    // MARK: - Conversation
    override func sendMessage(_ message: QBChatMessage) {
        super.sendMessage(message)
        
        if let conversation = self.conversation {
            conversation.expiration = NSDate().addingTimeInterval(30)
            conversation.lastMessage = message.text
            conversation.saveInBackground()
        }
    }
}
