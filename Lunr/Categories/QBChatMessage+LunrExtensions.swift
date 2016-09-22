//
//  QBChatMessage+LunrExtensions.swift
//  Lunr
//
//  Created by Brent Raines on 9/22/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Foundation
import QMChatViewController
import QMServices

extension QBChatMessage {
    func viewClass(withOpponentID opponentID: UInt) -> AnyClass! {
        // TODO: check and add QMMessageType.AcceptContactRequest, QMMessageType.RejectContactRequest, QMMessageType.ContactRequest
        if isNotificatonMessage() {
            return QMChatNotificationCell.self
        } else if (senderID != opponentID) {
            if (isMediaMessage() && attachmentStatus != QMMessageAttachmentStatus.Error) {
                return QMChatAttachmentIncomingCell.self
            } else {
                return QMChatIncomingCell.self
            }
        } else {
            if (isMediaMessage() && attachmentStatus != QMMessageAttachmentStatus.Error) {
                return QMChatAttachmentOutgoingCell.self
            } else {
                return QMChatOutgoingCell.self
            }
        }
    }
    
    func attributedString(withOpponentID opponentID: UInt) -> NSAttributedString? {
        guard text != nil else {
            return nil
        }
        
        var textColor = senderID == opponentID ? UIColor.whiteColor() : UIColor.blackColor()
        if isNotificatonMessage() {
            textColor = UIColor.blackColor()
        }
        
        var attributes = Dictionary<String, AnyObject>()
        attributes[NSForegroundColorAttributeName] = textColor
        attributes[NSFontAttributeName] = UIFont(name: "Helvetica", size: 17)
        
        return NSAttributedString(string: text!, attributes: attributes)
    }
    
    func topLabelAttributedString(withOpponentID opponentID: UInt, forDialog dialog: QBChatDialog) -> NSAttributedString? {
        guard senderID != opponentID && dialog.type != QBChatDialogType.Private else { return nil }
        
        let paragrpahStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragrpahStyle.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        var attributes = Dictionary<String, AnyObject>()
        attributes[NSForegroundColorAttributeName] = UIColor(red: 11.0/255.0, green: 96.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        attributes[NSFontAttributeName] = UIFont(name: "Helvetica", size: 17)
        attributes[NSParagraphStyleAttributeName] = paragrpahStyle
        
        var topLabelAttributedString : NSAttributedString?
        
        if let topLabelText = QBUserService.instance().usersService.usersMemoryStorage.userWithID(senderID)?.login {
            topLabelAttributedString = NSAttributedString(string: topLabelText, attributes: attributes)
        } else { // no user in memory storage
            topLabelAttributedString = NSAttributedString(string: "\(senderID)", attributes: attributes)
        }
        
        return topLabelAttributedString
    }
    
    func bottomLabelAttributedString(withOpponentID opponentID: UInt, forDialog dialog: QBChatDialog) -> NSAttributedString? {
        let textColor = senderID == opponentID ? UIColor.whiteColor() : UIColor.blackColor()
        
        let paragrpahStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragrpahStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        
        var attributes = Dictionary<String, AnyObject>()
        attributes[NSForegroundColorAttributeName] = textColor
        attributes[NSFontAttributeName] = UIFont(name: "Helvetica", size: 13)
        attributes[NSParagraphStyleAttributeName] = paragrpahStyle
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "HH:mm"
        var text = dateSent != nil ? formatter.stringFromDate(dateSent!) : ""
        
        if senderID == opponentID {
            text = text + "\n" + statusString(opponentID)
        }
        
        let bottomLabelAttributedString = NSAttributedString(string: text, attributes: attributes)
        
        return bottomLabelAttributedString
    }
    
    /**
     Builds a string
     Read: login1, login2, login3
     Delivered: login1, login3, @12345
     
     If user does not exist in usersMemoryStorage, then ID will be used instead of login
     
     - parameter message: QBChatMessage instance
     
     - returns: status string
     */
    private func statusString(opponentID: UInt) -> String {
        var statusString = ""
        let currentUserID = NSNumber(unsignedInteger: opponentID)
        var readLogins: [String] = []
        
        if readIDs != nil {
            let messageReadIDs = readIDs!.filter { (element : NSNumber) -> Bool in
                return !element.isEqualToNumber(currentUserID)
            }
            
            if !messageReadIDs.isEmpty {
                for readID in messageReadIDs {
                    let user = QBUserService.instance().usersService.usersMemoryStorage.userWithID(UInt(readID))
                    
                    guard let unwrappedUser = user else {
                        let unknownUserLogin = "@\(readID)"
                        readLogins.append(unknownUserLogin)
                        
                        continue
                    }
                    
                    readLogins.append(unwrappedUser.login!)
                }
                
                statusString += isMediaMessage() ? "Status" : "Read";
                statusString += ": " + readLogins.joinWithSeparator(", ")
            }
        }
        
        if deliveredIDs != nil {
            var deliveredLogins: [String] = []
            
            let messageDeliveredIDs = deliveredIDs!.filter { (element : NSNumber) -> Bool in
                return !element.isEqualToNumber(currentUserID)
            }
            
            if !messageDeliveredIDs.isEmpty {
                for deliveredID in messageDeliveredIDs {
                    let user = QBUserService.instance().usersService.usersMemoryStorage.userWithID(UInt(deliveredID))
                    
                    guard let unwrappedUser = user else {
                        let unknownUserLogin = "@\(deliveredID)"
                        deliveredLogins.append(unknownUserLogin)
                        
                        continue
                    }
                    
                    if readLogins.contains(unwrappedUser.login!) {
                        continue
                    }
                    
                    deliveredLogins.append(unwrappedUser.login!)
                }
                
                if readLogins.count > 0 && deliveredLogins.count > 0 {
                    statusString += "\n"
                }
                
                if deliveredLogins.count > 0 {
                    statusString += "Status" + ": " + deliveredLogins.joinWithSeparator(", ")
                }
            }
        }
        
        if statusString.isEmpty {
            statusString = "Status"
        }
        
        return statusString
    }
}