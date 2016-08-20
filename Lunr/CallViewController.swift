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
    case NoSession // session token to QuickBlox does not exist or expired
    case Disconnected // no chatroom/webrtc joined
    case Joining // currently joining the chatroom
    case Waiting // in the chat but no one else is; sending call signal
    case Connected // both people are in
}

class CallViewController: UIViewController {
    var targetPFUser: PFUser? {
        didSet {
            self.loadUser()
        }
    }
    var targetQBUUser: QBUUser? {
        didSet {
            self.refreshState()
        }
    }
    
    var session: QBRTCSession?
    var incomingSession: QBRTCSession?
    
    var videoCapture: QBRTCCameraCapture?
    var state: CallState = .Disconnected
    
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
        QBRTCClient.initializeRTC()
        QBRTCClient.instance().addDelegate(self)
        self.state = .Disconnected

        QBChat.instance().addDelegate(self)
        if !QBChat.instance().isConnected {
            self.state = .NoSession // on startup, button is disabled
            
            UserService.sharedInstance.refreshSession({ (success) in
                if !success {
                    self.simpleAlert("Failed user session", message: "Please log in again.", completion: {
                        self.navigationController?.popViewControllerAnimated(true)
                    })
                }
                else {
                    self.state = .Disconnected
                    self.refreshState()
                }
            })
        }

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.refreshState()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // UI states
    func refreshState() {
        
        switch state {
        case .NoSession:
            self.buttonCall.enabled = false
            self.buttonCall.alpha = 0.5
        case .Disconnected:
            self.buttonCall.enabled = true
            self.buttonCall.alpha = 1
        case .Joining:
            self.buttonCall.setTitle("Calling...", forState: .Normal)
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Done, target: self, action: #selector(CallViewController.endCall))
        default:
            break
        }
    }
    
    func loadUser() {
        if let pfUser = targetPFUser {
            UserService.getQBUUserFor(pfUser, completion: { (result) in
                self.targetQBUUser = result
            })
        }
    }
    
    // Back button action on navigation item
    func didClickBack() {
        if self.state == .Disconnected {
            self.navigationController?.popViewControllerAnimated(true)
        }
        else {
            print("invalid state")
        }
    }
    
    // Main action button
    @IBAction func didClickButton(button: UIButton) {
        if self.state == .Disconnected {
            self.startCall()
        }
        else {
            print("invalid state")
        }
    }
}

// MARK: - Call actions
extension CallViewController {
    func startCall() {
        guard let user = self.targetQBUUser else {
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
        
        self.state = .Joining
        self.refreshState()
    }
    
    func endCall() {
        self.session?.hangUp(nil)
        
        // TODO: end video stream
    }
}

extension CallViewController: QBChatDelegate{
    // MARK: - QBChatDelegate - initial connection
    func chatDidNotConnectWithError(error: NSError?) {
        print("error: \(error)")
    }
    
    func chatDidConnect() {
        print("didconnect")
    }
}

extension CallViewController: QBRTCClientDelegate {
    // MARK: - QBRTCClientDelegate
    //
    // MARK: Outbound connections
    func session(session: QBRTCSession!, acceptedByUser userID: NSNumber!, userInfo: [NSObject : AnyObject]!) {
        print("call accepted")
        
    }
    
    func session(session: QBRTCSession!, rejectedByUser userID: NSNumber!, userInfo: [NSObject : AnyObject]!) {
        print("call rejected")

        self.endCall()
    }
    
    // MARK: Inbound connections - only for provider?
    func didReceiveNewSession(session: QBRTCSession!, userInfo: [NSObject : AnyObject]!) {
        self.incomingSession = session
        if (self.session != nil) {
            // automatically reject call if a session exists
            return
        }

        let userId = self.incomingSession!.initiatorID as UInt
        QBRequest.userWithID(userId, successBlock: { (response, user) in
            print("Incoming call from a known user with id \(user?.ID)")
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

