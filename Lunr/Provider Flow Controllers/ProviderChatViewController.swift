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
    var callViewController: CallViewController?
    var currentCall: Call? // saved here because we don't send the call parameters until a new controller is started and need to store this info
    
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
        print("Starting call service")
        self.openVideo()
    }
    
    func openVideo() {
        if let controller: CallViewController = UIStoryboard(name: "CallFlow", bundle: nil).instantiateViewControllerWithIdentifier("CallViewController") as? CallViewController {
            self.navigationController?.pushViewController(controller, animated: true)

            self.callViewController = controller
            // don't start call until local video stream is ready
            self.listenFor(NotificationType.VideoSession.VideoReady.rawValue, action: #selector(startSession), object: nil)
        }
    }
    
    func startSession() {
        // initiates call to recipient after video stream is ready
        guard let recipient = self.recipient else { return }
        guard let userId = incomingPFUserId else { return }
        SessionService.sharedInstance.startCall(recipient.ID, pfUserId: userId)
        // start listening for incoming session
        self.listenForAcceptSession()
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
                if TEST {
                    if success {
                        self.simpleAlert("Push sent!", message: "You have successfully \(status) video chat with \(user.fullName ?? "someone")")
                    }
                    else {
                        self.simpleAlert("Client is not available", defaultMessage: nil, error: nil)
                    }
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
        let oldValue = userInfo?["oldValue"] as? String
        switch SessionService.sharedInstance.state {
        case .Connected:
            print("yay")
        case .Disconnected:
            self.cleanupLastSession(oldValue == CallState.Connected.rawValue)
        default:
            break
        }
    }
    
    func cleanupLastSession(wasConnected: Bool) {
        // ends listeners and pops controller. video should automatically stop
        self.callViewController?.endCall(wasConnected)
        self.callViewController = nil
    }

    /* TODO: 
     - handle close button in client side chat
       - provider received notification and hasn't clicked "Reply"
       - provider has not received notification yet
     - handle back button from client in video chat
       - client side close session
       - provider side listen for notification and close session
     - handle back button from provider in video chat
       - provider side close session
       - client side listen for notification and close session
     - provider side handle time out after starting video session (DONE)
       - show "Client No longer available" message?
     - handle client chat window closed
       - provider side listen for chat dialog close notification and close chat
     - handle provider chat window closed (DONE?)
       - client side listen for push notification and close chat
     */
}
