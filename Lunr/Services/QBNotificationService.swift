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
class QBNotificationService {
    var delegate: NotificationServiceDelegate?
    var pushDialogID: String?
    
    func handlePushNotificationWithDelegate(delegate: NotificationServiceDelegate!) {
        guard let dialogID = self.pushDialogID where !dialogID.isEmpty else { return }
        self.delegate = delegate;
		
        QBUserService.instance().chatService.fetchDialogWithID(dialogID) { [weak self] chatDialog in
			guard let strongSelf = self else { return }
			if let chatDialog = chatDialog {
				strongSelf.pushDialogID = nil;
				strongSelf.delegate?.notificationServiceDidSucceedFetchingDialog(chatDialog);
			} else {
                strongSelf.delegate?.notificationServiceDidStartLoadingDialogFromServer()
                QBUserService.instance().chatService.loadDialogWithID(dialogID) { loadedDialog in
                    guard let unwrappedDialog = loadedDialog else {
                        strongSelf.delegate?.notificationServiceDidFailFetchingDialog()
                        return
                    }
                    
                    strongSelf.delegate?.notificationServiceDidFinishLoadingDialogFromServer()
                    strongSelf.delegate?.notificationServiceDidSucceedFetchingDialog(unwrappedDialog)
                    
                }
            }
            
        }
    }
}