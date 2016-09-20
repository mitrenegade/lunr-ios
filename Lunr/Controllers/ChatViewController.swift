//
//  ChatViewController.swift
//  Lunr
//
//  Created by Brent Raines on 9/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import QMChatViewController

class ChatViewController: QMChatViewController {
    
    // MARK: Properties
    var targetPFUser: PFUser? {
        didSet {
            loadUser()
        }
    }
    var targetQBUUser: QBUUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chat"
        
        let currentQBUUser = QBSession.currentSession().currentUser
        let userID = currentQBUUser?.ID ?? 2000
        let displayName = currentQBUUser?.fullName ?? ""
        
        senderID = userID
        senderDisplayName = displayName
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: UInt, senderDisplayName: String!, date: NSDate!) {
        let message = QBChatMessage()
        message.text = text
        message.senderID = senderId
        message.dateSent = NSDate()
        
        chatSectionManager.addMessage(message)
        finishSendingMessageAnimated(true)
    }
    
    override func didPickAttachmentImage(image: UIImage!) {
        let resizedImage = resizedImageFromImage(image)
        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        
        guard let basePath: NSString = paths.first else { return }
        let binaryImageData = UIImagePNGRepresentation(resizedImage)
        let imageName = "\(NSDate().timeIntervalSince1970)-attachment.png"
        let imagePath = basePath.stringByAppendingPathComponent(imageName)
        
        binaryImageData?.writeToFile(imagePath, atomically: true)
        
        let message = QBChatMessage()
        message.senderID = senderID
        
        let attachment = QBChatAttachment()
        attachment.url = imagePath
        
        message.attachments = [attachment]
        message.dateSent = NSDate()
        
        chatSectionManager.addMessage(message)
        dispatch_async(dispatch_get_main_queue()) {
            self.finishSendingMessageAnimated(true)
        }
    }
    
    override func viewClassForItem(item: QBChatMessage?) -> AnyClass? {
        guard let item = item else { return nil }
        switch item.senderID {
        case QBChatMessage.MessageType.ContactRequest.rawValue:
            if item.senderID != self.senderID {
                return QMChatContactRequestCell.self
            }
        case QBChatMessage.MessageType.RejectContactRequest.rawValue:
            return QMChatNotificationCell.self
        case QBChatMessage.MessageType.AcceptContactRequest.rawValue:
            return QMChatNotificationCell.self
        default:
            if item.senderID != self.senderID {
                if let attachments = item.attachments where attachments.count > 0 {
                    return QMChatAttachmentIncomingCell.self
                } else {
                    return QMChatIncomingCell.self
                }
            } else {
                if let attachments = item.attachments where attachments.count > 0 {
                    return QMChatAttachmentOutgoingCell.self
                } else {
                    return QMChatOutgoingCell.self
                }
            }
        }
        
        return nil
    }
    
    override func collectionView(collectionView: QMChatCollectionView!, dynamicSizeAtIndexPath indexPath: NSIndexPath!, maxWidth: CGFloat) -> CGSize {
        let item = chatSectionManager.messageForIndexPath(indexPath)
        let viewClass = viewClassForItem(item).dynamicType
        
        var size = CGSize.zero
        
        if viewClass == QMChatAttachmentIncomingCell.self || viewClass == QMChatAttachmentOutgoingCell.self {
            size = CGSize(width: min(200, maxWidth), height: 200)
        } else {
            let attrString = attributedStringForItem(item)
            size = TTTAttributedLabel.sizeThatFitsAttributedString(
                attrString,
                withConstraints: CGSize(width: maxWidth, height: CGFloat.max),
                limitedToNumberOfLines: 0
            )
        }
        
        return size
    }
    
    override func collectionView(collectionView: QMChatCollectionView!, configureCell cell: UICollectionViewCell!, forIndexPath indexPath: NSIndexPath!) {
        if let attachmentCell = cell as? QMChatAttachmentCell {
            let message = chatSectionManager.messageForIndexPath(indexPath)
            if let attachment = message.attachments?.first {
                guard let url = attachment.url else { return }
                guard let imageData = NSData(contentsOfFile: url) else { return }
                attachmentCell.setAttachmentImage(UIImage(data: imageData))
                cell.updateConstraints()
            }
        }
        
        super.collectionView(collectionView, configureCell: cell, forIndexPath: indexPath)
    }
    
    override func attributedStringForItem(messageItem: QBChatMessage?) -> NSAttributedString! {
        return NSAttributedString(string: messageItem?.text ?? "")
    }
    
    override func collectionView(collectionView: QMChatCollectionView!, minWidthAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        var size = CGSize.zero
        if let item = chatSectionManager.messageForIndexPath(indexPath) {
            let attrString = item.senderID == senderID ? bottomLabelAttributedStringForItem(item) : topLabelAttributedStringForItem(item)
            size = TTTAttributedLabel.sizeThatFitsAttributedString(
                attrString,
                withConstraints: CGSize(width: 1000, height: 1000),
                limitedToNumberOfLines: 0
            )
        }
        
        return size.width
    }
    
    override func collectionView(collectionView: QMChatCollectionView!, layoutModelAtIndexPath indexPath: NSIndexPath!) -> QMChatCellLayoutModel {
        var layoutModel = super.collectionView(collectionView, layoutModelAtIndexPath: indexPath)
        layoutModel.avatarSize = CGSize.zero
        
        if let item = chatSectionManager.messageForIndexPath(indexPath) {
            let topLabelString = topLabelAttributedStringForItem(item)
            let size = TTTAttributedLabel.sizeThatFitsAttributedString(
                topLabelString,
                withConstraints: CGSize(width: CGRectGetWidth(collectionView.frame), height: CGFloat.max),
                limitedToNumberOfLines: 1
            )
            layoutModel.topLabelHeight = size.height
        }
        
        return layoutModel
    }
    
    override func bottomLabelAttributedStringForItem(messageItem: QBChatMessage?) -> NSAttributedString? {
        guard let messageItem = messageItem else { return nil }
        return NSAttributedString(string: timeStampWithDate(messageItem.dateSent))
    }
    
    override func topLabelAttributedStringForItem(messageItem: QBChatMessage?) -> NSAttributedString? {
        guard let messageItem = messageItem where messageItem.senderID != senderID else { return nil }
        return NSAttributedString(string: "")
    }
    
    private func timeStampWithDate(date: NSDate?) -> String {
        guard let date = date else { return "" }
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        return dateFormatter.stringFromDate(date)
    }
    
    private func resizedImageFromImage(image: UIImage) -> UIImage {
        let largestSide = image.size.width > image.size.height ? image.size.width: image.size.height
        let scaleCoefficient = largestSide / 560.0
        let newSize = CGSize(width: image.size.width / scaleCoefficient, height: image.size.height / scaleCoefficient)
        
        UIGraphicsBeginImageContext(newSize)
        image.drawInRect(CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func loadUser() {
        if let pfUser = targetPFUser {
            QBUserService.getQBUUserFor(pfUser, completion: { (result) in
                self.targetQBUUser = result
            })
        }
    }
}
