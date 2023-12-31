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
    
    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    
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
            self.rightBarButton.customView?.alpha = 0.5
            self.rightBarButton.isEnabled = false
            self.loadUser()
        }
    }
    
    func loadUser() {
        // load user
        guard let pfUserId = incomingPFUserId else { return }
        QBUserService.getQBUUserForPFUserId(pfUserId, completion: { (result) in
            if let qbClient = result {
                self.rightBarButton.customView?.alpha = 1
                self.rightBarButton.isEnabled = true
                self.updateTitle()
            }
            else {
                self.simpleAlert("Could not load user", message: "The user of the incoming chat could not be loaded", completion: { 
                    self.dismiss(nil)
                })
            }
        })
    }

    @IBAction override func dismiss(_ sender: AnyObject?) {
        self.dismiss(animated: true) { 
        }
    }

    @IBAction func startCall(_ sender: AnyObject) {
        print("Starting call service")
        self.openVideo()
    }
    
    func openVideo() {
        if let controller: CallViewController = UIStoryboard(name: "CallFlow", bundle: nil).instantiateViewController(withIdentifier: "CallViewController") as? CallViewController {
            controller.recipient = self.recipient
            self.navigationController?.pushViewController(controller, animated: true)

            self.callViewController = controller
            // don't start call until local video stream is ready
            self.listenFor(NotificationType.VideoSession.VideoReady.rawValue, action: #selector(startSession), object: nil)

            if let user = PFUser.current() as? User {
                user.updateActive()
                print("updateActive")
            }
        }
    }
    
    func startSession() {
        // initiates call to recipient after video stream is ready
        guard let recipient = self.recipient else { return }
        guard let userId = incomingPFUserId else { return }
        SessionService.sharedInstance.startCall(recipient.id, pfUserId: userId)
        // start listening for incoming session
        self.listenForAcceptSession()
    }

    // MARK: Session
    func listenForAcceptSession() {
        self.listenFor(NotificationType.VideoSession.CallStateChanged.rawValue, action: #selector(handleSessionState(_:)), object: nil)
    }

    func handleSessionState(_ notification: Notification) {
        let userInfo = notification.userInfo
        let oldValue = userInfo?["oldValue"] as? String
        switch SessionService.sharedInstance.state {
        case .Connected:
            print("yay")
        case .Disconnected:
            self.cleanupLastSession(oldValue == CallState.Connected.rawValue)
        case .Rejected:
            print("rejected - do not charge")
            self.cleanupLastSession(false)
        default:
            break
        }
    }
    
    func cleanupLastSession(_ wasConnected: Bool) {
        // ends listeners and pops controller. video should automatically stop
        self.callViewController?.endCall(wasConnected)
        self.callViewController = nil
        
        self.stopListeningFor(NotificationType.VideoSession.CallStateChanged.rawValue)
        self.stopListeningFor(NotificationType.VideoSession.VideoReady.rawValue)
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
