//
//  CallViewController.swift
//  RenderChat
//
//  Created by Bobby Ren on 2/25/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Quickblox
import Parse

// Selector Syntatic sugar: https://medium.com/swift-programming/swift-selector-syntax-sugar-81c8a8b10df3#.a6ml91o38
private extension Selector {
    // private to only this swift file
    static let didClickBack =
        #selector(CallViewController.didClickBack)
    static let didClickButton =
        #selector(CallViewController.didClickButton(_:))
}

enum CallState {
    case None
    case IncomingCallSameUser
    case IncomingCallDifferentUser
    case OutgoingCall
    case CurrentCall
}

class CallViewController: UIViewController, QBRTCClientDelegate, QBChatDelegate {

    var targetUser: PFUser?

    var callingUser: QBUUser?
    var session: QBRTCSession?
    var incomingSession: QBRTCSession?
    
    var videoCapture: QBRTCCameraCapture?
    var state: CallState = .None
    
    // remote video
    @IBOutlet weak var remoteVideoView: QBRTCRemoteVideoView!
    @IBOutlet weak var labelRemote: UILabel!
    
    // local video
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var labelLocal: UILabel!
    
    // call controls
    @IBOutlet weak var buttonCall: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // for now, no calling
        self.buttonCall.enabled = false
        
        // Do any additional setup after loading the view, typically from a nib.
        guard let target = targetUser else {
            return // this error will be handled on viewDidAppear
        }
        
        UserService.loadUsersWithCompletion { (results) in
            guard let users = results else {
                return
            }
            
            for user in users {
                if let _ = user.login where user.login == target.objectId! {
                    self.callingUser = user
                }
            }
            
            if let _ = self.callingUser {
                self.simpleAlert("Calling enabled", message: "Click to call \(target.displayString)", completion: {
                })
            }
            else {
                self.simpleAlert("Calling disabled", message: "Could not find QBUUser with id \(target.objectId)", completion: {
                    self.navigationController?.popViewControllerAnimated(true)
                })
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        guard self.targetUser != nil else {
            print("no user selected. handle this error!")
            self.simpleAlert("No user selected", message: "You cannot make a call without selecting a recipient.", completion: {
                self.navigationController?.popViewControllerAnimated(true)
            })
            return
        }
        
        if !QBChat.instance().isConnected {
            QBRTCClient.initializeRTC()
            QBRTCClient.instance().addDelegate(self)
            
            // these should not happen!
            guard let qbUser = QBSession.currentSession().currentUser else {
                print("No qbUser, handle this error!")
                self.simpleAlert("Invalid user session", message: "Please log in again.", completion: {
                    self.navigationController?.popViewControllerAnimated(true)
                })
                return
            }
            
            guard let pfUser = PFUser.currentUser() else {
                self.simpleAlert("Invalid user session", message: "Please log in again.", completion: {
                    self.navigationController?.popViewControllerAnimated(true)
                })
                return
            }
            
            qbUser.password = pfUser.objectId!
            
            QBChat.instance().addDelegate(self)
            QBChat.instance().connectWithUser(qbUser) { (error) in
                if error != nil {
                    print("error: \(error)")
                }
                else {
                    print("login to chat succeeded")
                }
            }
        }
        self.refreshState()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - QBChatDelegate - initial connection
    func chatDidNotConnectWithError(error: NSError?) {
        print("error: \(error)")
    }
    
    func chatDidConnect() {
        print("didconnect")
    }

    // MARK: - Call state
    func updateState(newState: CallState) {
        self.state = newState
        self.refreshState()
    }
    
    func refreshState() {
        if self.state == .None {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .Done, target: self, action: .didClickBack)

            self.buttonCall.setTitle("Call", forState: .Normal)
            
//            self.labelRemote.text = "Initiate call with \(self.targetUser!.displayString)"
        }
        else if self.state == .OutgoingCall {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Done, target: self, action: .didClickBack)

            self.buttonCall.setTitle("Cancel", forState: .Normal)

//            self.labelRemote.text = "Waiting for \(self.targetUser!.displayString)"
        }
        else if self.state == .IncomingCallSameUser {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Decline", style: .Done, target: self, action: #selector(CallViewController.didClickBack))

            self.buttonCall.setTitle("Answer", forState: .Normal)

//            self.labelRemote.text = "Call from \(self.targetUser!.displayString). Answer?"
        }
        else if self.state == .IncomingCallDifferentUser {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Decline", style: .Done, target: self, action: .didClickBack)

            self.buttonCall.setTitle("Answer", forState: .Normal)

//            self.labelRemote.text = "Call from \(self.targetUser!.displayString). Answer?"
            
            // uses incomingUser and switches current user views
            // TODO: different label than labelRemote?
        }
        else if self.state == .CurrentCall {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Decline", style: .Done, target: self, action: .didClickBack)

//            self.labelRemote.text = "In call with \(self.targetUser!.displayString)"

            self.buttonCall.setTitle("Hang up", forState: .Normal)
        }
        else {
            print("invalid state")
        }
    }
    
    // Back button action on navigation item
    func didClickBack() {
        if self.state == .None {
            self.navigationController?.popViewControllerAnimated(true)
        }
        else if self.state == .OutgoingCall {
            self.endCall()
        }
        else if self.state == .IncomingCallSameUser {
            self.rejectCall()
        }
        else if self.state == .IncomingCallDifferentUser {
            self.rejectCall()
        }
        else if self.state == .CurrentCall {
            self.endCall()
        }
        else {
            print("invalid state")
        }
    }
    
    // Main action button
    @IBAction func didClickButton(button: UIButton) {
        if self.state == .None {
            self.startCall()
        }
        else if self.state == .OutgoingCall {
            self.endCall()
        }
        else if self.state == .IncomingCallSameUser {
            self.acceptCall()
        }
        else if self.state == .IncomingCallDifferentUser {
            self.acceptCall()
        }
        else if self.state == .CurrentCall {
            self.endCall()
        }
        else {
            print("invalid state")
        }
    }
    
    // MARK: - User actions
    func startCall() {
        guard let user = self.callingUser else {
            self.simpleAlert("Calling disabled", message: "Could not find QBUUser to call", completion: {
            })
            return
        }
        
        // load video view
        self.loadVideoView()
        
        // create and start session
        let id = user.ID
        let newSession: QBRTCSession = QBRTCClient.instance().createNewSessionWithOpponents([id], withConferenceType: QBRTCConferenceType.Video)
        self.session = newSession
        self.session!.startCall(nil)
        
        self.buttonCall.setTitle("Calling...", forState: .Normal)
        self.buttonCall.enabled = false
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Done, target: self, action: #selector(CallViewController.endCall))
    }

    func endCall() {
        self.session?.hangUp(nil)
        
        // TODO: end video stream
    }
    
    func acceptCall() {
        if self.incomingSession != nil {
            self.session = self.incomingSession
            self.incomingSession = nil

            // TODO
        }
        
        self.session?.acceptCall(nil)
        self.loadVideoView()
        
        self.updateState(.CurrentCall)
    }
    
    func rejectCall() {
        // reject incoming call
        self.incomingSession?.rejectCall(nil)
    }
    
    // MARK: - QBRTCClientDelegate
    //
    // MARK: Outbound connections
    func session(session: QBRTCSession!, acceptedByUser userID: NSNumber!, userInfo: [NSObject : AnyObject]!) {
        print("call accepted")
        
        self.updateState(.CurrentCall)
    }
    
    func session(session: QBRTCSession!, rejectedByUser userID: NSNumber!, userInfo: [NSObject : AnyObject]!) {
        print("call rejected")
        self.endCall()
    }
    
    // MARK: Inbound connections
    func didReceiveNewSession(session: QBRTCSession!, userInfo: [NSObject : AnyObject]!) {
        self.incomingSession = session
        if (self.session != nil) {
            // automatically reject call if a session exists
            self.rejectCall()
            return
        }

        let userId = self.incomingSession!.initiatorID as UInt
        QBRequest.userWithID(userId, successBlock: { (response, user) in
            if userId == self.callingUser!.ID {
                self.updateState(.IncomingCallSameUser)
            }
            else {
                self.callingUser = user
                self.updateState(.IncomingCallDifferentUser)
            }
        }) { (response) in
            print("UserID could not be loaded")
        }
    }
    
    // MARK: All connections
    func session(session: QBRTCSession!, hungUpByUser userID: NSNumber!, userInfo: [NSObject : AnyObject]!) {
        print("session hung up")
        self.endCall()
    }
    
    func sessionDidClose(session: QBRTCSession!) {
        print("Session closed")
        // notified when all remotes are inactive
        self.session = nil
    }
    
    // MARK: - Video
    func loadVideoView() {
        let width: UInt = UInt(self.localVideoView.frame.size.width)
        let height: UInt = UInt(self.localVideoView.frame.size.height)
        let videoFormat = QBRTCVideoFormat(width: width, height: height, frameRate: 30, pixelFormat: .Format420f)
        self.videoCapture = QBRTCCameraCapture(videoFormat: videoFormat, position: .Front)
        self.videoCapture!.previewLayer.frame = self.localVideoView.bounds
        self.videoCapture!.startSession()
        self.localVideoView.layer.insertSublayer(self.videoCapture!.previewLayer, atIndex: 0)
    }

    func session(session: QBRTCSession!, initializedLocalMediaStream mediaStream: QBRTCMediaStream!) {
        mediaStream.videoTrack.videoCapture = self.videoCapture
    }
    
    func session(session: QBRTCSession!, receivedRemoteVideoTrack videoTrack: QBRTCVideoTrack!, fromUser userID: NSNumber!) {
        self.remoteVideoView.setVideoTrack(videoTrack)
    }
}

