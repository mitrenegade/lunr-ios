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
import Quickblox
import QMServices

enum CallState: String {
//    case NoSession // session token to QuickBlox does not exist or expired
    case Disconnected // no chatroom/webrtc joined
//    case Joining // currently joining the chatroom
//    case Waiting // in the chat but no one else is; sending call signal
    case Connected // both people are in
}

class SessionService: QMServicesManager, QBRTCClientDelegate {
    static var _instance: SessionService?
    static var sharedInstance: SessionService {
        get {
            if _instance != nil {
                return _instance!
            }
            _instance = SessionService()
            QBRTCClient.initializeRTC()
            QBRTCClient.instance().addDelegate(_instance)
            QBRTCConfig.setAnswerTimeInterval(30)
            return _instance!
        }
    }
    var session: QBRTCSession?
    var incomingSession: QBRTCSession?
    var isRefreshingSession: Bool = false

    var currentDialogID = ""

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

    // MARK: QMChatServiceDelegate
    
    override func chatService(chatService: QMChatService, didAddMessageToMemoryStorage message: QBChatMessage, forDialogID dialogID: String) {
        super.chatService(chatService, didAddMessageToMemoryStorage: message, forDialogID: dialogID)
        
        if authService.isAuthorized {
            handleNewMessage(message, dialogID: dialogID)
        }
    }
    
    func handleNewMessage(message: QBChatMessage, dialogID: String) {
//        guard currentDialogID != dialogID else { return }
//        guard message.senderID != currentUser()?.ID else { return }
//        guard let dialog = chatService.dialogsMemoryStorage.chatDialogWithID(dialogID) else { return }
//
//        var dialogName = "New Message"
//        if dialog.type != QBChatDialogType.Private {
//            if dialog.name != nil {
//                dialogName = dialog.name!
//            }
//        } else {
//            if let user = SessionService.sharedInstance.usersService.usersMemoryStorage.userWithID(UInt(dialog.recipientID)) {
//                dialogName = user.login!
//            }
//        }
//
//        QMMessageNotificationManager.showNotificationWithTitle(dialogName, subtitle: message.text, type: QMMessageNotificationType.Info)
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
            NSNotificationCenter.defaultCenter().postNotificationName(NotificationType.VideoSession.CallStateChanged.rawValue, object: nil, userInfo: ["state":state.rawValue])
        }
    }
    
    // MARK: Session lifecycle
    
    // user action (provider)
    func startCall(userID: UInt) {
        // create and start session
        let newSession: QBRTCSession = QBRTCClient.instance().createNewSessionWithOpponents([userID], withConferenceType: QBRTCConferenceType.Video)
        self.session = newSession
        let userInfo: [String: AnyObject]? = nil // send any info through
        self.session!.startCall(userInfo)
    }

    // delegate (client)
    func didReceiveNewSession(session: QBRTCSession!, userInfo: [NSObject : AnyObject]!) {
        self.incomingSession = session
        if (self.session != nil) {
            // automatically reject call if a session exists
            return
        }
        
        let userId = self.incomingSession!.initiatorID as UInt
        QBUserService.qbUUserWithId(userId) { (result) in
            if let user = result {
                print("Incoming call from a known user with id \(user.ID)")
                self.session = self.incomingSession
                self.state = .Connected
            }
            else {
                self.incomingSession = nil
                print("UserID could not be loaded")
            }
        }
    }
    
    // user action (client)
    func acceptCall(userInfo: [String: AnyObject]?) {
        // happens automatically when client receives an incoming call and goes to video view
        self.session?.acceptCall(userInfo)
    }
    
    func rejectCall(userInfo: [String: AnyObject]?) {
        // might happen if client is already in a call and goes to video view...shouldn't happen
        self.session?.rejectCall(userInfo)
    }
    
    // delegate (provider)
    func session(session: QBRTCSession!, acceptedByUser userID: NSNumber!, userInfo: [NSObject : AnyObject]!) {
        print("call accepted")
        self.state = .Connected
    }
    
    func session(session: QBRTCSession!, rejectedByUser userID: NSNumber!, userInfo: [NSObject : AnyObject]!) {
        print("call rejected")
        self.state = .Disconnected
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
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationType.VideoSession.StreamInitialized.rawValue, object: nil, userInfo: nil)
        // BOBBY TODO
        //mediaStream.videoTrack.videoCapture = self.videoCapture
    }
    
    func session(session: QBRTCSession!, receivedRemoteVideoTrack videoTrack: QBRTCVideoTrack!, fromUser userID: NSNumber!) {
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationType.VideoSession.VideoReceived.rawValue, object: nil, userInfo: nil)
        // BOBBY TODO
        // self.remoteVideoView.setVideoTrack(videoTrack)
    }
    
}