//
//  VideoSessionService.swift
//  Lunr
//
//  Created by Bobby Ren on 10/4/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//
// manages video sessions

import UIKit
import Parse

enum CallState {
//    case NoSession // session token to QuickBlox does not exist or expired
    case Disconnected // no chatroom/webrtc joined
//    case Joining // currently joining the chatroom
//    case Waiting // in the chat but no one else is; sending call signal
    case Connected // both people are in
}

class VideoSessionService: NSObject, QBRTCClientDelegate {
    var session: QBRTCSession?
    var isRefreshingSession: Bool = false

    // MARK: Refresh user session
    func refreshChatSession(completion: ((success: Bool) -> Void)?) {
        // if not connected to QBChat. For example at startup
        // TODO: make this part of the Session service
        guard !isRefreshingSession else { return }
        isRefreshingSession = true
        
        guard let qbUser = QBSession.currentSession().currentUser else {
            print("No qbUser, handle this error!")
            completion?(success: false)
            return
        }
        
        guard let pfUser = PFUser.currentUser() else {
            completion?(success: false)
            return
        }
        
        qbUser.password = pfUser.objectId!
        QBChat.instance().connectWithUser(qbUser) { (error) in
            self.isRefreshingSession = false
            if error != nil {
                print("error: \(error)")
                completion?(success: false)
            }
            else {
                print("login to chat succeeded")
                completion?(success: true)
            }
        }
    }

    /*
    extension CallViewController: QBChatDelegate{
        // MARK: - QBChatDelegate - initial connection
        func chatDidNotConnectWithError(error: NSError?) {
            print("error: \(error)")
        }
        
        func chatDidConnect() {
            print("didconnect")
        }
    }
    */
    
    // MARK: - QBRTCClientDelegate
    var state: CallState = .Disconnected {
        didSet {
            self.notify(.CallStateChanged, object: nil, userInfo: ["state":state])
        }
    }
    
    // MARK: Outbound connections
    func session(session: QBRTCSession!, acceptedByUser userID: NSNumber!, userInfo: [NSObject : AnyObject]!) {
        print("call accepted")
        self.state = .Connected
    }
    
    func session(session: QBRTCSession!, rejectedByUser userID: NSNumber!, userInfo: [NSObject : AnyObject]!) {
        print("call rejected")
        self.state = .Disconnected
    }
    
    // MARK: Inbound connections - only for provider?
    func didReceiveNewSession(session: QBRTCSession!, userInfo: [NSObject : AnyObject]!) {
        self.incomingSession = session
        if (self.session != nil) {
            // automatically reject call if a session exists
            return
        }
        
        let userId = self.incomingSession!.initiatorID as UInt
        QBUserService.qbUUserWithId(userId) { (result) in
            if let user = result {
                print("Incoming call from a known user with id \(user?.ID)")
                self.session = self.incomingSession
                self.state = .Connected
            }
            else {
                self.incomingSession = nil
                print("UserID could not be loaded")
            }
        }
    }
    
    // MARK: All connections
    func session(session: QBRTCSession!, hungUpByUser userID: NSNumber!, userInfo: [NSObject : AnyObject]!) {
        print("session hung up")
        self.session = nil
        self.state = .Disconnected
    }
    
    func sessionDidClose(session: QBRTCSession!) {
        print("Session closed")
        // notified when all remotes are inactive
        self.session = nil
        self.state = .Disconnected
    }
    
    func session(session: QBRTCSession!, initializedLocalMediaStream mediaStream: QBRTCMediaStream!) {
        mediaStream.videoTrack.videoCapture = self.videoCapture
    }
    
    func session(session: QBRTCSession!, receivedRemoteVideoTrack videoTrack: QBRTCVideoTrack!, fromUser userID: NSNumber!) {
        self.remoteVideoView.setVideoTrack(videoTrack)
    }
}