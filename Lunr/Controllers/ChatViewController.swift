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
import QMServices
import SafariServices
import CoreTelephony

class ChatViewController: QMChatViewController, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: Properties
	let messageContainerWidthPadding: CGFloat = 40.0
    let maxCharactersNumber = 1024 // 0 - unlimited
    var willResignActiveBlock: AnyObject?
    var attachmentCellsMap: NSMapTable!
    var detailedCells: Set<String> = []
    var typingTimer: NSTimer?
    var popoverController: UIViewController? {
        didSet {
            popoverController?.modalPresentationStyle = .Popover
        }
    }
    var dialog: QBChatDialog!
    var recipient: QBUUser?
    
    lazy var imagePickerViewController : UIImagePickerController = {
        let imagePickerViewController = UIImagePickerController()
        imagePickerViewController.delegate = self
        
        return imagePickerViewController
    }()
    
    var unreadMessages: [QBChatMessage]?
    
    private func loginCurrentQBUser() {
        guard let currentUser = PFUser.currentUser() else {
            dismissWithError(nil)
            return
        }
        
        if !QBChat.instance().isConnected {
            QBUserService.sharedInstance.loginQBUser(currentUser.objectId!) { [weak self] (success, error) in
                guard success && error == nil else {
                    self?.dismissWithError(error)
                    return
                }
            }
        }
    }
    
    private func configureSender() {
        if let qbCurrentUser = QBSession.currentSession().currentUser {
            senderID = qbCurrentUser.ID
            senderDisplayName = qbCurrentUser.login
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSender()
        loginCurrentQBUser()
        
        // top layout inset for collectionView
        topContentAdditionalInset = (navigationController?.navigationBar.frame.size.height ?? 0) + UIApplication.sharedApplication().statusBarFrame.size.height
        
        heightForSectionHeader = 40.0
        
        collectionView?.backgroundColor = UIColor.whiteColor()
        inputToolbar?.contentView?.backgroundColor = UIColor.whiteColor()
        inputToolbar?.contentView?.textView?.placeHolder = "Start typing"
        
        attachmentCellsMap = NSMapTable(keyOptions: NSPointerFunctionsOptions.StrongMemory, valueOptions: NSPointerFunctionsOptions.WeakMemory)
        
        QBUserService.instance().chatService.addDelegate(self)
        QBUserService.instance().chatService.chatAttachmentService.delegate = self
        
        enableTextCheckingTypes = NSTextCheckingAllTypes
        
        QBUserService.instance().currentDialogID = dialog.ID!
        updateTitle()
        if (storedMessages()?.count > 0 && chatSectionManager.totalMessagesCount == 0) {
            chatSectionManager.addMessages(storedMessages()!)
        }
        
        loadMessages()
        
        if dialog.type == QBChatDialogType.Private {
            dialog.onUserIsTyping = { [weak self] userID in
                self?.title = "Typing"
            }
            
            dialog.onUserStoppedTyping = { [weak self] userID in
                self?.updateTitle()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        willResignActiveBlock = NSNotificationCenter.defaultCenter().addObserverForName(
            UIApplicationWillResignActiveNotification,
            object: nil,
            queue: nil,
            usingBlock: { [weak self] notification in
                self?.fireSendStopTypingIfNecessary()
            })
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let willResignActive = willResignActiveBlock {
            NSNotificationCenter.defaultCenter().removeObserver(willResignActive)
        }
        
        // Resetting current dialog ID.
        QBUserService.instance().currentDialogID = ""
        
        // clearing typing status blocks
        dialog.clearTypingStatusBlocks()
    }
    
    private func dismissWithError(error: NSError?) {
        dismissViewControllerAnimated(true) { [weak presentingViewController] _ in
            presentingViewController?.simpleAlert("Error", defaultMessage: "There was an error connecting your chat", error: error)
        }
    }
    
    @IBAction func dismiss(sender: AnyObject?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Update
    
    func updateTitle() {
        if dialog.type != QBChatDialogType.Private {
            title = dialog.name
        } else {
            if let recipient = QBUserService.qbUUserWithId(dialog.recipientID) {
                title = recipient.fullName
                self.recipient = recipient
            }
            else {
                self.title = "New Chat"
            }
        }
    }
        
    func storedMessages() -> [QBChatMessage]? {
        return QBUserService.instance().chatService.messagesMemoryStorage.messagesWithDialogID(dialog.ID!)
    }
    
    func loadMessages() {
        // Retrieving messages for chat dialog ID.
        guard let currentDialogID = dialog.ID else { return }
        QBUserService.instance().chatService.messagesWithChatDialogID(currentDialogID) { [weak self] response, messages in
            guard let strongSelf = self where response.error == nil else {
                self?.simpleAlert("There was an error retrieving your messages", defaultMessage: nil, error: response.error as? NSError)
                return
            }
            
            if messages?.count > 0 {
                strongSelf.chatSectionManager.addMessages(messages)
            }
        }
    }
    
    func sendReadStatusForMessage(message: QBChatMessage) {
        guard let currentUser = QBSession.currentSession().currentUser where message.senderID != currentUser.ID else { return }
        let currentUserID = NSNumber(unsignedInteger: currentUser.ID)
        
        if (message.readIDs == nil || !message.readIDs!.contains(currentUserID)) {
            QBUserService.instance().chatService.readMessage(message) { error in
                guard error == nil else { return }
                
                if UIApplication.sharedApplication().applicationIconBadgeNumber > 0 {
                    let badgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber
                    UIApplication.sharedApplication().applicationIconBadgeNumber = badgeNumber - 1
                }
            }
        }
    }
    
    func readMessages(messages: [QBChatMessage]) {
        if QBChat.instance().isConnected {
            QBUserService.instance().chatService.readMessages(messages, forDialogID: dialog.ID!, completion: nil)
        } else {
            unreadMessages = messages
        }
        
        var messageIDs = [String]()
        
        for message in messages {
            messageIDs.append(message.ID!)
        }
    }
    
    // MARK: Actions
    
    override func didPickAttachmentImage(image: UIImage!) {
        let message = QBChatMessage()
        message.senderID = senderID
        message.dialogID = dialog.ID
        message.dateSent = NSDate()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [weak self] () -> Void in
            guard let strongSelf = self else { return }
            var newImage : UIImage! = image
            if strongSelf.imagePickerViewController.sourceType == UIImagePickerControllerSourceType.Camera {
                newImage = newImage.fixOrientation()
            }
            
            let largestSide = newImage.size.width > newImage.size.height ? newImage.size.width : newImage.size.height
            let scaleCoeficient = largestSide/560.0
            let newSize = CGSize(width: newImage.size.width/scaleCoeficient, height: newImage.size.height/scaleCoeficient)
            
            // create smaller image
            
            UIGraphicsBeginImageContext(newSize)
            
            newImage.drawInRect(CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            // Sending attachment.
            dispatch_async(dispatch_get_main_queue()) {
                QBUserService
                    .instance()
                    .chatService
                    .sendAttachmentMessage(
                        message,
                        toDialog: strongSelf.dialog,
                        withAttachmentImage: resizedImage
                    ) { [weak self] error in
                        self?.attachmentCellsMap.removeObjectForKey(message.ID)
                        guard error != nil else { return }
                        
                        // perform local attachment message deleting if error
                        QBUserService.instance().chatService.deleteMessageLocally(message)
                        self?.chatSectionManager.deleteMessage(message)
                }
            }
        }
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: UInt, senderDisplayName: String!, date: NSDate!) {
        let shouldJoin = dialog.type == .Group ? !dialog.isJoined() : false
        if !QBChat.instance().isConnected || shouldJoin {
            if shouldJoin {
                simpleAlert("Error", defaultMessage: "Failed to send", error: nil)
            }
        
            return
        }
        
        fireSendStopTypingIfNecessary()
        
        let message = QBChatMessage()
        message.text = text
        message.senderID = senderID
        message.deliveredIDs = [(senderID)]
        message.readIDs = [(senderID)]
        message.markable = true
        message.dateSent = date
        
        sendMessage(message)
    }
    
    func sendMessage(message: QBChatMessage) {
        QBUserService
            .instance()
            .chatService
            .sendMessage(
                message,
                toDialogID: dialog.ID!,
                saveToHistory: true,
                saveToStorage: true
            ) { [weak self] error in
                if let error = error {
                    self?.simpleAlert("Error", defaultMessage: nil, error: error)
                }
        }
        
        finishSendingMessageAnimated(true)
    }
    
    // MARK: Helper
    func canMakeACall() -> Bool {
        var canMakeACall = false
        
        if (UIApplication.sharedApplication().canOpenURL(NSURL.init(string: "tel://")!)) {
            // Check if iOS Device supports phone calls
            let networkInfo = CTTelephonyNetworkInfo()
            let carrier = networkInfo.subscriberCellularProvider
            if carrier == nil {
                return false
            }
            let mnc = carrier?.mobileNetworkCode
            if mnc?.characters.count == 0 {
                // Device cannot place a call at this time.  SIM might be removed.
            } else {
                // iOS Device is capable for making calls
                canMakeACall = true
            }
        } else {
            // iOS Device is not capable for making calls
        }
        
        return canMakeACall
    }

    func showCharactersNumberError() {
        let title  = "Error";
        let subtitle = String(format: "The character limit is %lu.", maxCharactersNumber)
        simpleAlert(title, defaultMessage: subtitle, error: nil)
    }
    
    // MARK: Override
    
    override func viewClassForItem(item: QBChatMessage) -> AnyClass! {
        return item.viewClass(withOpponentID: senderID)
    }
    
    // MARK: Strings builder
    
    override func attributedStringForItem(messageItem: QBChatMessage!) -> NSAttributedString? {
        return messageItem.attributedString(withOpponentID: senderID)
    }
    
    /**
     Creates top label attributed string from QBChatMessage
     
     - parameter messageItem: QBCHatMessage instance
     
     - returns: login string, example: @SwiftTestDevUser1
     */
    override func topLabelAttributedStringForItem(messageItem: QBChatMessage!) -> NSAttributedString? {
        return messageItem.topLabelAttributedString(withOpponentID: senderID, forDialog: dialog)
    }
    
    /**
     Creates bottom label attributed string from QBChatMessage using statusStringFromMessage
     
     - parameter messageItem: QBChatMessage instance
     
     - returns: bottom label status string
     */
    override func bottomLabelAttributedStringForItem(messageItem: QBChatMessage!) -> NSAttributedString! {
        return messageItem.bottomLabelAttributedString(withOpponentID: senderID, forDialog: dialog)
    }
}

// MARK: QMChatCellDelegate
extension ChatViewController: QMChatCellDelegate {
    
    // Removes size from cache for item to allow cell expand and show read/delivered IDS or unexpand cell
    func chatCellDidTapContainer(cell: QMChatCell!) {
        let indexPath = collectionView?.indexPathForCell(cell)
        guard let currentMessageID = chatSectionManager.messageForIndexPath(indexPath).ID else { return }
        
        if detailedCells.contains(currentMessageID) {
            detailedCells.remove(currentMessageID)
        } else {
            detailedCells.insert(currentMessageID)
        }
        
        collectionView?.collectionViewLayout.removeSizeFromCacheForItemID(currentMessageID)
        collectionView?.performBatchUpdates(nil, completion: nil)
    }
    
    func chatCell(cell: QMChatCell!, didTapAtPosition position: CGPoint) {}
    
    func chatCell(cell: QMChatCell!, didPerformAction action: Selector, withSender sender: AnyObject!) {}
    
    func chatCell(cell: QMChatCell!, didTapOnTextCheckingResult result: NSTextCheckingResult) {
        switch result.resultType {
        case NSTextCheckingType.Link:
            let strUrl : String = (result.URL?.absoluteString)!
            let hasPrefix = strUrl.lowercaseString.hasPrefix("https://") || strUrl.lowercaseString.hasPrefix("http://")
            if hasPrefix {
                let controller = SFSafariViewController(URL: NSURL(string: strUrl)!)
                presentViewController(controller, animated: true, completion: nil)
                
                break
            }
            
            break
            
        case NSTextCheckingType.PhoneNumber:
            if !canMakeACall() {
                simpleAlert("Your device can't make a phone call", defaultMessage: nil, error: nil)
                break
            }
            
            let urlString = String(format: "tel:%@",result.phoneNumber!)
            let url = NSURL(string: urlString)
            
            view.endEditing(true)
            
            let alertController = UIAlertController(
                title: "",
                message: result.phoneNumber,
                preferredStyle: .Alert
            )
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            let openAction = UIAlertAction(title: "Call", style: .Destructive) { action in
                UIApplication.sharedApplication().openURL(url!)
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(openAction)
            presentViewController(alertController, animated: true, completion: nil)
            
            break
            
        default:
            break
        }
    }
    
    func chatCellDidTapAvatar(cell: QMChatCell!) {}
}

// MARK: Collection View Datasource/Delegate
extension ChatViewController {
    override func collectionView(collectionView: QMChatCollectionView!, dynamicSizeAtIndexPath indexPath: NSIndexPath!, maxWidth: CGFloat) -> CGSize {
        var size = CGSize.zero
        guard let message = chatSectionManager.messageForIndexPath(indexPath) else { return size }
        
        let messageCellClass: AnyClass! = viewClassForItem(message)
        
        if messageCellClass === QMChatAttachmentIncomingCell.self {
            size = CGSize(width: min(200, maxWidth), height: 200)
        } else if messageCellClass === QMChatAttachmentOutgoingCell.self {
            let attributedString = bottomLabelAttributedStringForItem(message)
            let bottomLabelSize = TTTAttributedLabel.sizeThatFitsAttributedString(attributedString, withConstraints: CGSize(width: min(200, maxWidth), height: CGFloat.max), limitedToNumberOfLines: 0)
            size = CGSize(width: min(200, maxWidth), height: 200 + ceil(bottomLabelSize.height))
        } else if messageCellClass === QMChatNotificationCell.self {
            let attributedString = attributedStringForItem(message)
            size = TTTAttributedLabel.sizeThatFitsAttributedString(attributedString, withConstraints: CGSize(width: maxWidth, height: CGFloat.max), limitedToNumberOfLines: 0)
        } else {
            let attributedString = attributedStringForItem(message)
            size = TTTAttributedLabel.sizeThatFitsAttributedString(attributedString, withConstraints: CGSize(width: maxWidth, height: CGFloat.max), limitedToNumberOfLines: 0)
        }
        
        return size
    }
    
    override func collectionView(collectionView: QMChatCollectionView!, minWidthAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        var size = CGSize.zero
        guard let item = chatSectionManager.messageForIndexPath(indexPath) else { return 0 }
        
        if detailedCells.contains(item.ID!) {
            let str = bottomLabelAttributedStringForItem(item)
            let frameWidth = CGRectGetWidth(collectionView.frame)
            let maxHeight = CGFloat.max
            
            size = TTTAttributedLabel.sizeThatFitsAttributedString(str, withConstraints: CGSize(width:frameWidth - messageContainerWidthPadding, height: maxHeight), limitedToNumberOfLines:0)
        }
        
        if dialog.type != QBChatDialogType.Private {
            let topLabelSize = TTTAttributedLabel.sizeThatFitsAttributedString(topLabelAttributedStringForItem(item), withConstraints: CGSize(width: CGRectGetWidth(collectionView.frame) - messageContainerWidthPadding, height: CGFloat.max), limitedToNumberOfLines:0)
            
            if topLabelSize.width > size.width {
                size = topLabelSize
            }
        }
        
        return size.width
    }
    
    override func collectionView(collectionView: QMChatCollectionView!, layoutModelAtIndexPath indexPath: NSIndexPath!) -> QMChatCellLayoutModel {
        var layoutModel: QMChatCellLayoutModel = super.collectionView(collectionView, layoutModelAtIndexPath: indexPath)
        
        layoutModel.avatarSize = CGSize(width: 0, height: 0)
        layoutModel.topLabelHeight = 0.0
        layoutModel.spaceBetweenTextViewAndBottomLabel = 5
        layoutModel.maxWidthMarginSpace = 20.0
        
        guard let item = chatSectionManager.messageForIndexPath(indexPath) else {
            return layoutModel
        }
        
        let viewClass: AnyClass = viewClassForItem(item) as AnyClass
        if viewClass === QMChatIncomingCell.self || viewClass === QMChatAttachmentIncomingCell.self {
            if dialog.type != QBChatDialogType.Private {
                let topAttributedString = topLabelAttributedStringForItem(item)
                let size = TTTAttributedLabel.sizeThatFitsAttributedString(topAttributedString, withConstraints: CGSize(width: CGRectGetWidth(collectionView.frame) - messageContainerWidthPadding, height: CGFloat.max), limitedToNumberOfLines:1)
                layoutModel.topLabelHeight = size.height
            }
            
            layoutModel.spaceBetweenTopLabelAndTextView = 5
        }
        
        var size = CGSizeZero
        
        if detailedCells.contains(item.ID!) {
            let bottomAttributedString = bottomLabelAttributedStringForItem(item)
            size = TTTAttributedLabel.sizeThatFitsAttributedString(bottomAttributedString, withConstraints: CGSize(width: CGRectGetWidth(collectionView.frame) - messageContainerWidthPadding, height: CGFloat.max), limitedToNumberOfLines:0)
        }
        
        layoutModel.bottomLabelHeight = floor(size.height)
        
        return layoutModel
    }
    
    override func collectionView(collectionView: QMChatCollectionView!, configureCell cell: UICollectionViewCell!, forIndexPath indexPath: NSIndexPath!) {
        super.collectionView(collectionView, configureCell: cell, forIndexPath: indexPath)
        
        // subscribing to cell delegate
        let chatCell = cell as! QMChatCell
        chatCell.delegate = self
        
        if let attachmentCell = cell as? QMChatAttachmentCell {
            if attachmentCell is QMChatAttachmentIncomingCell {
                chatCell.containerView?.bgColor = UIColor(red: 226.0/255.0, green: 226.0/255.0, blue: 226.0/255.0, alpha: 1.0)
            } else if attachmentCell is QMChatAttachmentOutgoingCell {
                chatCell.containerView?.bgColor = UIColor(red: 10.0/255.0, green: 95.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            }
            
            let message = chatSectionManager.messageForIndexPath(indexPath)
            if let attachment = message.attachments?.first {
                var keysToRemove: [String] = []
                let enumerator = attachmentCellsMap.keyEnumerator()
                
                while let existingAttachmentID = enumerator.nextObject() as? String {
                    let cachedCell = attachmentCellsMap.objectForKey(existingAttachmentID)
                    if cachedCell === cell {
                        keysToRemove.append(existingAttachmentID)
                    }
                }
                
                for key in keysToRemove {
                    attachmentCellsMap.removeObjectForKey(key)
                }
                
                attachmentCellsMap.setObject(attachmentCell, forKey: attachment.ID)
                attachmentCell.attachmentID = attachment.ID
                
                // Getting image from chat attachment cache.
                
                QBUserService
                    .instance()
                    .chatService
                    .chatAttachmentService
                    .imageForAttachmentMessage(message) { [weak self] error, image in
                        guard attachmentCell.attachmentID == attachment.ID else { return }
                        self?.attachmentCellsMap.removeObjectForKey(attachment.ID)
                        guard error == nil else {
                            self?.simpleAlert("There was an error", defaultMessage: nil, error: error)
                            return
                        }
                        
                        attachmentCell.setAttachmentImage(image)
                        cell.updateConstraints()
                }
            }
            
        } else if cell is QMChatIncomingCell || cell is QMChatAttachmentIncomingCell {
            chatCell.containerView?.bgColor = UIColor(red: 226.0/255.0, green: 226.0/255.0, blue: 226.0/255.0, alpha: 1.0)
        } else if cell is QMChatOutgoingCell || cell is QMChatAttachmentOutgoingCell {
            chatCell.containerView?.bgColor = UIColor(red: 10.0/255.0, green: 95.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        } else if cell is QMChatNotificationCell {
            cell.userInteractionEnabled = false
            chatCell.containerView?.bgColor = collectionView?.backgroundColor
        }
    }
    
    // Allows to copy text from QMChatIncomingCell and QMChatOutgoingCell
    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject!) -> Bool {
        guard let item = chatSectionManager.messageForIndexPath(indexPath) else { return false }
        
        let viewClass: AnyClass = viewClassForItem(item) as AnyClass
        
        if viewClass === QMChatAttachmentIncomingCell.self ||
            viewClass === QMChatAttachmentOutgoingCell.self ||
            viewClass === QMChatNotificationCell.self ||
            viewClass === QMChatContactRequestCell.self {
            return false
        }
        
        return super.collectionView(collectionView, canPerformAction: action, forItemAtIndexPath: indexPath, withSender: sender)
    }
    
    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject!) {
        guard action == #selector(NSObject.copy(_:)) else { return }
        
        let item = chatSectionManager.messageForIndexPath(indexPath)
        let viewClass : AnyClass = viewClassForItem(item) as AnyClass
        
        if viewClass === QMChatAttachmentIncomingCell.self ||
            viewClass === QMChatAttachmentOutgoingCell.self ||
            viewClass === QMChatNotificationCell.self ||
            viewClass === QMChatContactRequestCell.self {
            
            return
        }
        
        UIPasteboard.generalPasteboard().string = item.text
        
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let lastSection = (collectionView.numberOfSections()) - 1
        
        if (indexPath.section == lastSection && indexPath.item == (collectionView.numberOfItemsInSection(lastSection)) - 1) {
            // the very first message
            // load more if exists
            // Getting earlier messages for chat dialog identifier.
            
            guard let dialogID = dialog.ID else {
                return super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
            }
            
            QBUserService.instance().chatService.loadEarlierMessagesWithChatDialogID(dialogID).continueWithBlock({ [weak self] task in
                guard let strongSelf = self else { return nil }
                if (task.result?.count > 0) {
                    strongSelf.chatSectionManager.addMessages(task.result as! [QBChatMessage]!)
                }
                
                return nil
            })
        }
        
        // marking message as read if needed
        if let message = chatSectionManager.messageForIndexPath(indexPath) {
            sendReadStatusForMessage(message)
        }
        
        return super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
    }
}


// MARK: QMChatServiceDelegate
extension ChatViewController: QMChatServiceDelegate {
    func chatService(chatService: QMChatService, didLoadMessagesFromCache messages: [QBChatMessage], forDialogID dialogID: String) {
        if dialog.ID == dialogID {
            chatSectionManager.addMessages(messages)
        }
    }
    
    func chatService(chatService: QMChatService, didAddMessageToMemoryStorage message: QBChatMessage, forDialogID dialogID: String) {
        if dialog.ID == dialogID {
            // Insert message received from XMPP or self sent
            chatSectionManager.addMessage(message)
        }
    }
    
    func chatService(chatService: QMChatService, didUpdateChatDialogInMemoryStorage chatDialog: QBChatDialog) {
        if dialog.type != QBChatDialogType.Private && dialog.ID == chatDialog.ID {
            dialog = chatDialog
            title = dialog.name
        }
    }
    
    func chatService(chatService: QMChatService, didUpdateMessage message: QBChatMessage, forDialogID dialogID: String) {
        if dialog.ID == dialogID {
            chatSectionManager.updateMessage(message)
        }
        
    }
    
    func chatService(chatService: QMChatService, didUpdateMessages messages: [QBChatMessage], forDialogID dialogID: String) {
        if dialog.ID == dialogID {
            chatSectionManager.updateMessages(messages)
        }
        
    }
}

// MARK: QMChatAttachmentServiceDelegate
extension ChatViewController: QMChatAttachmentServiceDelegate {
    func chatAttachmentService(chatAttachmentService: QMChatAttachmentService, didChangeAttachmentStatus status: QMMessageAttachmentStatus, forMessage message: QBChatMessage) {
        if status != QMMessageAttachmentStatus.NotLoaded {
            if message.dialogID == dialog.ID {
                chatSectionManager.updateMessage(message)
            }
        }
    }
    
    func chatAttachmentService(chatAttachmentService: QMChatAttachmentService, didChangeLoadingProgress progress: CGFloat, forChatAttachment attachment: QBChatAttachment) {
        if let attachmentCell = attachmentCellsMap.objectForKey(attachment.ID!) {
            attachmentCell.updateLoadingProgress(progress)
        }
    }
    
    func chatAttachmentService(chatAttachmentService: QMChatAttachmentService, didChangeUploadingProgress progress: CGFloat, forMessage message: QBChatMessage) {
        guard message.dialogID == dialog.ID else { return }
        var cell = attachmentCellsMap.objectForKey(message.ID)
        if cell == nil && progress < 1.0 {
            let indexPath = chatSectionManager.indexPathForMessage(message)
            cell = collectionView.cellForItemAtIndexPath(indexPath) as? QMChatAttachmentCell
            attachmentCellsMap.setObject(cell, forKey: message.ID)
        }
        
        cell?.updateLoadingProgress(progress)
    }
}

// MARK : QMChatConnectionDelegate
extension ChatViewController: QMChatConnectionDelegate {
    func refreshAndReadMessages() {
        loadMessages()
        
        if let messagesToRead = unreadMessages {
            readMessages(messagesToRead)
        }
        
        unreadMessages = nil
    }
    
    func chatServiceChatDidConnect(chatService: QMChatService) {
        refreshAndReadMessages()
    }
    
    func chatServiceChatDidReconnect(chatService: QMChatService) {
        refreshAndReadMessages()
    }
}

// MARK: UITextViewDelegate
extension ChatViewController {
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
    }
    
    override func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        // Prevent crashing undo bug
        let currentCharacterCount = textView.text?.characters.count ?? 0
        if (range.length + range.location > currentCharacterCount) {
            return false
        }
        
        if !QBChat.instance().isConnected { return true }
        
        if let timer = typingTimer {
            timer.invalidate()
            typingTimer = nil
        } else {
            sendBeginTyping()
        }
        
        typingTimer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: #selector(fireSendStopTypingIfNecessary), userInfo: nil, repeats: false)
        
        if maxCharactersNumber > 0 {
            if currentCharacterCount >= maxCharactersNumber && text.characters.count > 0 {
                showCharactersNumberError()
                return false
            }
            
            let newLength = currentCharacterCount + text.characters.count - range.length
            
            if newLength <= maxCharactersNumber || text.characters.count == 0 {
                return true
            }
            
            let oldString = textView.text ?? ""
            let numberOfSymbolsToCut = maxCharactersNumber - oldString.characters.count
            var stringRange = NSMakeRange(0, min(text.characters.count, numberOfSymbolsToCut))
            
            // adjust the range to include dependent chars
            stringRange = (text as NSString).rangeOfComposedCharacterSequencesForRange(stringRange)
            
            // Now you can create the short string
            let shortString = (text as NSString).substringWithRange(stringRange)
            
            let newText = NSMutableString()
            newText.appendString(oldString)
            newText.insertString(shortString, atIndex: range.location)
            textView.text = newText as String
            
            showCharactersNumberError()
            textViewDidChange(textView)
            
            return false
        }
        
        return true
    }
    
    override func textViewDidEndEditing(textView: UITextView) {
        super.textViewDidEndEditing(textView)
        fireSendStopTypingIfNecessary()
    }
    
    func fireSendStopTypingIfNecessary() -> Void {
        if let timer = typingTimer {
            timer.invalidate()
        }
        
        typingTimer = nil
        sendStopTyping()
    }
    
    func sendBeginTyping() -> Void {
        dialog.sendUserIsTyping()
    }
    
    func sendStopTyping() -> Void {
        dialog.sendUserStoppedTyping()
    }
}