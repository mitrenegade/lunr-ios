//
//  QBNotificationService.swift
//  Lunr
//
//  Created by Brent Raines on 9/20/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Foundation

protocol NotificationServiceDelegate {
    /**
    *  Is called when dialog fetching is complete and ready to return requested dialog
    *
    *  @param chatDialog QBChatDialog instance. Successfully fetched dialog
    */
    func notificationServiceDidSucceedFetchingDialog(chatDialog: QBChatDialog!)
    
    /**
    *  Is called when dialog was not found nor in memory storage nor in cache
    *  and NotificationService started requesting dialog from server
    */
    func notificationServiceDidStartLoadingDialogFromServer()
    
    /**
    *  Is called when dialog request from server was completed
    */
    func notificationServiceDidFinishLoadingDialogFromServer()
    
    /**
    *  Is called when dialog was not found in both memory storage and cache
    *  and server request return nil
    */
    func notificationServiceDidFailFetchingDialog()
}

/**
*  Service responsible for working with push notifications
*/
class QBNotificationService: NotificationServiceDelegate {
    static let sharedInstance: QBNotificationService = QBNotificationService()

    var delegate: NotificationServiceDelegate?
    var incomingPFUserId: String?
    var incomingDialogId: String? // dialogID to be pushed
    var currentDialogID: String? // open dialogID
    
    func handlePushNotification(userInfo: [NSObject: AnyObject]) {
        if let _ = userInfo["chatStatus"] as? String {
            self.handleChatInvite(userInfo)
        }
        else if let _ = userInfo["videoChatStatus"] as? String {
            self.handleChatResponse(userInfo)
        }
    }
    
    func handleChatInvite(userInfo: [NSObject: AnyObject]) {
        guard let dialogID = userInfo["dialogId"] as? String where !dialogID.isEmpty else { return }
        self.incomingDialogId = dialogID
        if self.currentDialogID == self.incomingDialogId {
            return
        }
        
        guard let incomingPFUserId = userInfo["pfUserId"] as? String else {
            return
        }
        QBNotificationService.sharedInstance.incomingPFUserId = incomingPFUserId
        
        // calling dispatch async for push notification handling to have priority in main queue
        dispatch_async(dispatch_get_main_queue(), {
            QBUserService.instance().chatService.fetchDialogWithID(dialogID) { [weak self] chatDialog in
                guard let strongSelf = self else { return }
                if let chatDialog = chatDialog {
                    strongSelf.incomingDialogId = nil;
                    strongSelf.notificationServiceDidSucceedFetchingDialog(chatDialog);
                } else {
                    strongSelf.notificationServiceDidStartLoadingDialogFromServer()
                    QBUserService.instance().chatService.loadDialogWithID(dialogID) { loadedDialog in
                        guard let unwrappedDialog = loadedDialog else {
                            self?.notificationServiceDidFailFetchingDialog()
                            return
                        }
                        
                        strongSelf.notificationServiceDidFinishLoadingDialogFromServer()
                        strongSelf.notificationServiceDidSucceedFetchingDialog(unwrappedDialog)
                        
                    }
                }
                
            }
        });
    }
    
    func handleChatResponse(userInfo: [NSObject: AnyObject]) {
        guard let status = userInfo["videoChatStatus"] as? String where !status.isEmpty else { return }
        guard let dialogID = userInfo["dialogId"] as? String where !dialogID.isEmpty else { return }
        self.incomingDialogId = dialogID
        
        if self.currentDialogID != self.incomingDialogId {
            return
        }
        
        // calling dispatch async for push notification handling to have priority in main queue
        dispatch_async(dispatch_get_main_queue(), {
            if status == "cancelled" {
                // close current chat
                NSNotificationCenter.defaultCenter().postNotificationName("video:cancelled", object: nil, userInfo: ["dialog": self.incomingDialogId ?? "", "pfUserId": self.incomingPFUserId ?? ""])
            }
            else if status == "started" {
                // go to video chat
                NSNotificationCenter.defaultCenter().postNotificationName("video:accepted", object: nil, userInfo: ["dialog": self.incomingDialogId ?? "", "pfUserId": self.incomingPFUserId ?? ""])
            }
        });
    }
    
    func clearDialog() {
        QBNotificationService.sharedInstance.currentDialogID = nil
        QBNotificationService.sharedInstance.incomingDialogId = nil
        QBNotificationService.sharedInstance.incomingPFUserId = nil
    }
    
    // MARK: NotificationServiceDelegate protocol
    func notificationServiceDidStartLoadingDialogFromServer() {
    }
    
    func notificationServiceDidFinishLoadingDialogFromServer() {
    }
    
    func notificationServiceDidSucceedFetchingDialog(chatDialog: QBChatDialog!) {
        NSNotificationCenter.defaultCenter().postNotificationName("dialog:fetched", object: nil, userInfo: ["dialog": chatDialog, "pfUserId": incomingPFUserId ?? ""])
    }
    
    func notificationServiceDidFailFetchingDialog() {
    }
    

}