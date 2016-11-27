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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ChatViewController: QMChatViewController, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: Properties
	let messageContainerWidthPadding: CGFloat = 40.0
    let maxCharactersNumber = 1024 // 0 - unlimited
    var willResignActiveBlock: AnyObject?
    var attachmentCellsMap: NSMapTable<AnyObject, AnyObject>!
    var detailedCells: Set<String> = []
    var typingTimer: Timer?
    var popoverController: UIViewController? {
        didSet {
            popoverController?.modalPresentationStyle = .popover
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
    
    fileprivate func configureSender() {
        if let qbCurrentUser = QBSession.current().currentUser {
            senderID = qbCurrentUser.id
            senderDisplayName = qbCurrentUser.login
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        QBUserService.sharedInstance.refreshUserSession { (success) in
            if success {
                self.continueLoad()
            }
            else {
                self.dismissWithError(nil)
            }
        }
        
        // top layout inset for collectionView
        topContentAdditionalInset = (navigationController?.navigationBar.frame.size.height ?? 0) + UIApplication.shared.statusBarFrame.size.height
        
        heightForSectionHeader = 40.0
        
        collectionView?.backgroundColor = UIColor.white
        inputToolbar?.contentView?.backgroundColor = UIColor.white
        inputToolbar?.contentView?.textView?.placeHolder = "Start typing"
        
        attachmentCellsMap = NSMapTable(keyOptions: NSPointerFunctions.Options(), valueOptions: NSPointerFunctions.Options.weakMemory)
        
        enableTextCheckingTypes = NSTextCheckingAllTypes
    }
    
    func continueLoad() {
        configureSender()
        
        SessionService.sharedInstance.chatService.addDelegate(self)
        SessionService.sharedInstance.chatService.chatAttachmentService.delegate = self
        SessionService.sharedInstance.currentDialogID = dialog.id!
        updateTitle()
        if (storedMessages()?.count > 0 && chatSectionManager.totalMessagesCount == 0) {
            chatSectionManager.add(storedMessages()!)
        }
        
        loadMessages()
        
        if dialog.type == QBChatDialogType.private {
            dialog.onUserIsTyping = { [weak self] userID in
                self?.title = "Typing"
            }
            
            dialog.onUserStoppedTyping = { [weak self] userID in
                self?.updateTitle()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        willResignActiveBlock = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.UIApplicationWillResignActive,
            object: nil,
            queue: nil,
            using: { [weak self] notification in
                self?.fireSendStopTypingIfNecessary()
            })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let willResignActive = willResignActiveBlock {
            NotificationCenter.default.removeObserver(willResignActive)
        }
        
        // Resetting current dialog ID.
        SessionService.sharedInstance.currentDialogID = ""
        
        // clearing typing status blocks
        dialog.clearTypingStatusBlocks()
    }
    
    fileprivate func dismissWithError(_ error: NSError?) {
        self.dismiss(animated: true) { [weak presentingViewController] _ in
            presentingViewController?.simpleAlert("Error", defaultMessage: "There was an error connecting to chat. Please log in again.", error: error)
        }
    }
    
    @IBAction func dismiss(_ sender: AnyObject?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Update
    
    func updateTitle() {
        if dialog.type != QBChatDialogType.private {
            title = dialog.name
        } else {
            if let recipient = QBUserService.cachedUserWithId(UInt(dialog.recipientID)) {
                title = recipient.fullName
                self.recipient = recipient
            }
            else {
                self.title = "New Chat"
            }
        }
    }
        
    func storedMessages() -> [QBChatMessage]? {
        return SessionService.sharedInstance.chatService.messagesMemoryStorage.messages(withDialogID: dialog.id!)
    }
    
    func loadMessages() {
        // Retrieving messages for chat dialog ID.
        guard let currentDialogID = dialog.id else { return }
        SessionService.sharedInstance.chatService.messages(withChatDialogID: currentDialogID) { [weak self] response, messages in
            guard let strongSelf = self, response.error == nil else {
                self?.simpleAlert("There was an error retrieving your messages", defaultMessage: nil, error: response.error as? NSError)
                return
            }
            
            if messages?.count > 0 {
                strongSelf.chatSectionManager.add(messages)
            }
        }
    }
    
    func sendReadStatusForMessage(_ message: QBChatMessage) {
        guard let currentUser = QBSession.current().currentUser, message.senderID != currentUser.id else { return }
        let currentUserID = NSNumber(value: currentUser.id as UInt)
        
        if (message.readIDs == nil || !message.readIDs!.contains(currentUserID)) {
            SessionService.sharedInstance.chatService.read(message) { error in
                guard error == nil else { return }
                
                if UIApplication.shared.applicationIconBadgeNumber > 0 {
                    let badgeNumber = UIApplication.shared.applicationIconBadgeNumber
                    UIApplication.shared.applicationIconBadgeNumber = badgeNumber - 1
                }
            }
        }
    }
    
    func readMessages(_ messages: [QBChatMessage]) {
        if QBChat.instance().isConnected {
            SessionService.sharedInstance.chatService.read(messages, forDialogID: dialog.id!, completion: nil)
        } else {
            unreadMessages = messages
        }
        
        var messageIDs = [String]()
        
        for message in messages {
            messageIDs.append(message.id!)
        }
    }
    
    // MARK: Actions
    
    override func didPickAttachmentImage(_ image: UIImage!) {
        let message = QBChatMessage()
        message.senderID = senderID
        message.dialogID = dialog.id
        message.dateSent = Date()
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async { [weak self] () -> Void in
            guard let strongSelf = self else { return }
            var newImage : UIImage! = image
            if strongSelf.imagePickerViewController.sourceType == UIImagePickerControllerSourceType.camera {
                newImage = newImage.fixOrientation()
            }
            
            let largestSide = newImage.size.width > newImage.size.height ? newImage.size.width : newImage.size.height
            let scaleCoeficient = largestSide/560.0
            let newSize = CGSize(width: newImage.size.width/scaleCoeficient, height: newImage.size.height/scaleCoeficient)
            
            // create smaller image
            
            UIGraphicsBeginImageContext(newSize)
            
            newImage.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            // Sending attachment.
            DispatchQueue.main.async {
                SessionService
                    .sharedInstance
                    .chatService
                    .sendAttachmentMessage(
                        message,
                        to: strongSelf.dialog,
                        withAttachmentImage: resizedImage!
                    ) { [weak self] error in
                        self?.attachmentCellsMap.removeObject(forKey: message.id as AnyObject?)
                        guard error != nil else { return }
                        
                        // perform local attachment message deleting if error
                        SessionService.sharedInstance.chatService.deleteMessageLocally(message)
                        self?.chatSectionManager.delete(message)
                }
            }
        }
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: UInt, senderDisplayName: String!, date: Date!) {
        let shouldJoin = dialog.type == .group ? !dialog.isJoined() : false
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
        message.deliveredIDs = [(NSNumber(senderID))]
        message.readIDs = [(NSNumber(senderID))]
        message.markable = true
        message.dateSent = date
        
        sendMessage(message)
    }
    
    func sendMessage(_ message: QBChatMessage) {
        SessionService
            .sharedInstance
            .chatService
            .send(
                message,
                toDialogID: dialog.id!,
                saveToHistory: true,
                saveToStorage: true
            ) { [weak self] error in
                if let error = error {
                    self?.simpleAlert("Error", defaultMessage: nil, error: error)
                }
        }
        
        finishSendingMessage(animated: true)
    }
    
    // MARK: Helper
    func canMakeACall() -> Bool {
        var canMakeACall = false
        
        if (UIApplication.shared.canOpenURL(URL.init(string: "tel://")!)) {
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
    
    override func viewClass(forItem item: QBChatMessage) -> AnyClass! {
        return item.viewClass(withOpponentID: senderID)
    }
    
    // MARK: Strings builder
    
    override func attributedString(forItem messageItem: QBChatMessage!) -> NSAttributedString? {
        return messageItem.attributedString(withOpponentID: senderID)
    }
    
    /**
     Creates top label attributed string from QBChatMessage
     
     - parameter messageItem: QBCHatMessage instance
     
     - returns: login string, example: @SwiftTestDevUser1
     */
    override func topLabelAttributedString(forItem messageItem: QBChatMessage!) -> NSAttributedString? {
        return messageItem.topLabelAttributedString(withOpponentID: senderID, forDialog: dialog)
    }
    
    /**
     Creates bottom label attributed string from QBChatMessage using statusStringFromMessage
     
     - parameter messageItem: QBChatMessage instance
     
     - returns: bottom label status string
     */
    override func bottomLabelAttributedString(forItem messageItem: QBChatMessage!) -> NSAttributedString! {
        return messageItem.bottomLabelAttributedString(withOpponentID: senderID, forDialog: dialog)
    }
}

// MARK: QMChatCellDelegate
extension ChatViewController: QMChatCellDelegate {
    
    // Removes size from cache for item to allow cell expand and show read/delivered IDS or unexpand cell
    func chatCellDidTapContainer(_ cell: QMChatCell!) {
        let indexPath = collectionView?.indexPath(for: cell)
        guard let currentMessageID = chatSectionManager.message(for: indexPath).id else { return }
        
        if detailedCells.contains(currentMessageID) {
            detailedCells.remove(currentMessageID)
        } else {
            detailedCells.insert(currentMessageID)
        }
        
        collectionView?.collectionViewLayout.removeSizeFromCache(forItemID: currentMessageID)
        collectionView?.performBatchUpdates(nil, completion: nil)
    }
    
    func chatCell(_ cell: QMChatCell!, didTapAtPosition position: CGPoint) {}
    
    func chatCell(_ cell: QMChatCell!, didPerformAction action: Selector, withSender sender: AnyObject!) {}
    
    func chatCell(_ cell: QMChatCell!, didTapOn result: NSTextCheckingResult) {
        switch result.resultType {
        case NSTextCheckingResult.CheckingType.link:
            let strUrl : String = (result.url?.absoluteString)!
            let hasPrefix = strUrl.lowercased().hasPrefix("https://") || strUrl.lowercased().hasPrefix("http://")
            if hasPrefix {
                let controller = SFSafariViewController(url: URL(string: strUrl)!)
                present(controller, animated: true, completion: nil)
                
                break
            }
            
            break
            
        case NSTextCheckingResult.CheckingType.phoneNumber:
            if !canMakeACall() {
                simpleAlert("Your device can't make a phone call", defaultMessage: nil, error: nil)
                break
            }
            
            let urlString = String(format: "tel:%@",result.phoneNumber!)
            let url = URL(string: urlString)
            
            view.endEditing(true)
            
            let alertController = UIAlertController(
                title: "",
                message: result.phoneNumber,
                preferredStyle: .alert
            )
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let openAction = UIAlertAction(title: "Call", style: .destructive) { action in
                UIApplication.shared.openURL(url!)
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(openAction)
            present(alertController, animated: true, completion: nil)
            
            break
            
        default:
            break
        }
    }
    
    func chatCellDidTapAvatar(_ cell: QMChatCell!) {}
}

// MARK: Collection View Datasource/Delegate
extension ChatViewController {
    override func collectionView(_ collectionView: QMChatCollectionView!, dynamicSizeAt indexPath: IndexPath!, maxWidth: CGFloat) -> CGSize {
        var size = CGSize.zero
        guard let message = chatSectionManager.message(for: indexPath) else { return size }
        
        let messageCellClass: AnyClass! = viewClass(forItem: message)
        
        if messageCellClass === QMChatAttachmentIncomingCell.self {
            size = CGSize(width: min(200, maxWidth), height: 200)
        } else if messageCellClass === QMChatAttachmentOutgoingCell.self {
            let attributedString = bottomLabelAttributedString(forItem: message)
            let bottomLabelSize = TTTAttributedLabel.sizeThatFitsAttributedString(attributedString, withConstraints: CGSize(width: min(200, maxWidth), height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines: 0)
            size = CGSize(width: min(200, maxWidth), height: 200 + ceil(bottomLabelSize.height))
        } else if messageCellClass === QMChatNotificationCell.self {
            let attributedString = self.attributedString(forItem: message)
            size = TTTAttributedLabel.sizeThatFitsAttributedString(attributedString, withConstraints: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines: 0)
        } else {
            let attributedString = self.attributedString(forItem: message)
            size = TTTAttributedLabel.sizeThatFitsAttributedString(attributedString, withConstraints: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines: 0)
        }
        
        return size
    }
    
    override func collectionView(_ collectionView: QMChatCollectionView!, minWidthAt indexPath: IndexPath!) -> CGFloat {
        var size = CGSize.zero
        guard let item = chatSectionManager.message(for: indexPath) else { return 0 }
        
        if detailedCells.contains(item.id!) {
            let str = bottomLabelAttributedString(forItem: item)
            let frameWidth = collectionView.frame.width
            let maxHeight = CGFloat.greatestFiniteMagnitude
            
            size = TTTAttributedLabel.sizeThatFitsAttributedString(str, withConstraints: CGSize(width:frameWidth - messageContainerWidthPadding, height: maxHeight), limitedToNumberOfLines:0)
        }
        
        if dialog.type != QBChatDialogType.private {
            let topLabelSize = TTTAttributedLabel.sizeThatFitsAttributedString(topLabelAttributedString(forItem: item), withConstraints: CGSize(width: collectionView.frame.width - messageContainerWidthPadding, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines:0)
            
            if topLabelSize.width > size.width {
                size = topLabelSize
            }
        }
        
        return size.width
    }
    
    override func collectionView(_ collectionView: QMChatCollectionView!, layoutModelAt indexPath: IndexPath!) -> QMChatCellLayoutModel {
        var layoutModel: QMChatCellLayoutModel = super.collectionView(collectionView, layoutModelAt: indexPath)
        
        layoutModel.avatarSize = CGSize(width: 0, height: 0)
        layoutModel.topLabelHeight = 0.0
        layoutModel.spaceBetweenTextViewAndBottomLabel = 5
        layoutModel.maxWidthMarginSpace = 20.0
        
        guard let item = chatSectionManager.message(for: indexPath) else {
            return layoutModel
        }
        
        let viewClass: AnyClass = self.viewClass(forItem: item) as AnyClass
        if viewClass === QMChatIncomingCell.self || viewClass === QMChatAttachmentIncomingCell.self {
            if dialog.type != QBChatDialogType.private {
                let topAttributedString = topLabelAttributedString(forItem: item)
                let size = TTTAttributedLabel.sizeThatFitsAttributedString(topAttributedString, withConstraints: CGSize(width: collectionView.frame.width - messageContainerWidthPadding, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines:1)
                layoutModel.topLabelHeight = size.height
            }
            
            layoutModel.spaceBetweenTopLabelAndTextView = 5
        }
        
        var size = CGSize.zero
        
        if detailedCells.contains(item.id!) {
            let bottomAttributedString = bottomLabelAttributedString(forItem: item)
            size = TTTAttributedLabel.sizeThatFitsAttributedString(bottomAttributedString, withConstraints: CGSize(width: collectionView.frame.width - messageContainerWidthPadding, height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines:0)
        }
        
        layoutModel.bottomLabelHeight = floor(size.height)
        
        return layoutModel
    }
    
    override func collectionView(_ collectionView: QMChatCollectionView!, configureCell cell: UICollectionViewCell!, for indexPath: IndexPath!) {
        super.collectionView(collectionView, configureCell: cell, for: indexPath)
        
        // subscribing to cell delegate
        let chatCell = cell as! QMChatCell
        chatCell.delegate = self
        
        if let attachmentCell = cell as? QMChatAttachmentCell {
            if attachmentCell is QMChatAttachmentIncomingCell {
                chatCell.containerView?.bgColor = UIColor(red: 226.0/255.0, green: 226.0/255.0, blue: 226.0/255.0, alpha: 1.0)
            } else if attachmentCell is QMChatAttachmentOutgoingCell {
                chatCell.containerView?.bgColor = UIColor(red: 10.0/255.0, green: 95.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            }
            
            let message = chatSectionManager.message(for: indexPath)
            if let attachment = message?.attachments?.first {
                var keysToRemove: [String] = []
                let enumerator = attachmentCellsMap.keyEnumerator()
                
                while let existingAttachmentID = enumerator.nextObject() as? String {
                    let cachedCell = attachmentCellsMap.object(forKey: existingAttachmentID as AnyObject?)
                    if cachedCell === cell {
                        keysToRemove.append(existingAttachmentID)
                    }
                }
                
                for key in keysToRemove {
                    attachmentCellsMap.removeObject(forKey: key as AnyObject?)
                }
                
                attachmentCellsMap.setObject(attachmentCell, forKey: attachment.id as AnyObject?)
                attachmentCell.attachmentID = attachment.id
                
                // Getting image from chat attachment cache.
                
                SessionService
                    .sharedInstance
                    .chatService
                    .chatAttachmentService
                    .image(forAttachmentMessage: message!) { [weak self] error, image in
                        guard attachmentCell.attachmentID == attachment.id else { return }
                        self?.attachmentCellsMap.removeObject(forKey: attachment.id as AnyObject?)
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
            cell.isUserInteractionEnabled = false
            chatCell.containerView?.bgColor = collectionView?.backgroundColor
        }
    }
    
    // Allows to copy text from QMChatIncomingCell and QMChatOutgoingCell
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: AnyObject!) -> Bool {
        guard let item = chatSectionManager.message(for: indexPath) else { return false }
        
        let viewClass: AnyClass = self.viewClass(forItem: item) as AnyClass
        
        if viewClass === QMChatAttachmentIncomingCell.self ||
            viewClass === QMChatAttachmentOutgoingCell.self ||
            viewClass === QMChatNotificationCell.self ||
            viewClass === QMChatContactRequestCell.self {
            return false
        }
        
        return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: AnyObject!) {
        guard action == #selector(NSObject.copy(_:)) else { return }
        
        let item = chatSectionManager.message(for: indexPath)
        let viewClass : AnyClass = self.viewClass(forItem: item!) as AnyClass
        
        if viewClass === QMChatAttachmentIncomingCell.self ||
            viewClass === QMChatAttachmentOutgoingCell.self ||
            viewClass === QMChatNotificationCell.self ||
            viewClass === QMChatContactRequestCell.self {
            
            return
        }
        
        UIPasteboard.general.string = item?.text
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let lastSection = (collectionView.numberOfSections) - 1
        
        if (indexPath.section == lastSection && indexPath.item == (collectionView.numberOfItems(inSection: lastSection)) - 1) {
            // the very first message
            // load more if exists
            // Getting earlier messages for chat dialog identifier.
            
            guard let dialogID = dialog.id else {
                return super.collectionView(collectionView, cellForItemAt: indexPath)
            }
            
            SessionService.sharedInstance.chatService.loadEarlierMessages(withChatDialogID: dialogID).continue({ [weak self] task in
                guard let strongSelf = self else { return nil }
                if (task.result?.count > 0) {
                    strongSelf.chatSectionManager.add(task.result as! [QBChatMessage]!)
                }
                
                return nil
            })
        }
        
        // marking message as read if needed
        if let message = chatSectionManager.message(for: indexPath) {
            sendReadStatusForMessage(message)
        }
        
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
}


// MARK: QMChatServiceDelegate
extension ChatViewController: QMChatServiceDelegate {
    func chatService(_ chatService: QMChatService, didLoadMessagesFromCache messages: [QBChatMessage], forDialogID dialogID: String) {
        if dialog.id == dialogID {
            chatSectionManager.add(messages)
        }
    }
    
    func chatService(_ chatService: QMChatService, didAddMessageToMemoryStorage message: QBChatMessage, forDialogID dialogID: String) {
        if dialog.id == dialogID {
            // Insert message received from XMPP or self sent
            chatSectionManager.add(message)
        }
    }
    
    func chatService(_ chatService: QMChatService, didUpdateChatDialogInMemoryStorage chatDialog: QBChatDialog) {
        if dialog.type != QBChatDialogType.private && dialog.id == chatDialog.id {
            dialog = chatDialog
            title = dialog.name
        }
    }
    
    func chatService(_ chatService: QMChatService, didUpdate message: QBChatMessage, forDialogID dialogID: String) {
        if dialog.id == dialogID {
            chatSectionManager.update(message)
        }
        
    }
    
    func chatService(_ chatService: QMChatService, didUpdate messages: [QBChatMessage], forDialogID dialogID: String) {
        if dialog.id == dialogID {
            chatSectionManager.update(messages)
        }
        
    }
}

// MARK: QMChatAttachmentServiceDelegate
extension ChatViewController: QMChatAttachmentServiceDelegate {
    func chatAttachmentService(_ chatAttachmentService: QMChatAttachmentService, didChange status: QMMessageAttachmentStatus, for message: QBChatMessage) {
        if status != QMMessageAttachmentStatus.notLoaded {
            if message.dialogID == dialog.id {
                chatSectionManager.update(message)
            }
        }
    }
    
    func chatAttachmentService(_ chatAttachmentService: QMChatAttachmentService, didChangeLoadingProgress progress: CGFloat, for attachment: QBChatAttachment) {
        if let attachmentCell = attachmentCellsMap.object(forKey: attachment.id! as AnyObject?) {
            attachmentCell.updateLoadingProgress(progress)
        }
    }
    
    func chatAttachmentService(_ chatAttachmentService: QMChatAttachmentService, didChangeUploadingProgress progress: CGFloat, for message: QBChatMessage) {
        guard message.dialogID == dialog.id else { return }
        var cell = attachmentCellsMap.object(forKey: message.id as AnyObject?)
        if cell == nil && progress < 1.0 {
            let indexPath = chatSectionManager.indexPath(for: message)
            cell = collectionView.cellForItem(at: indexPath!) as? QMChatAttachmentCell
            attachmentCellsMap.setObject(cell, forKey: message.id as AnyObject?)
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
    
    func chatServiceChatDidConnect(_ chatService: QMChatService) {
        refreshAndReadMessages()
    }
    
    func chatServiceChatDidReconnect(_ chatService: QMChatService) {
        refreshAndReadMessages()
    }
}

// MARK: UITextViewDelegate
extension ChatViewController {
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
    }
    
    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
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
        
        typingTimer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(fireSendStopTypingIfNecessary), userInfo: nil, repeats: false)
        
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
            stringRange = (text as NSString).rangeOfComposedCharacterSequences(for: stringRange)
            
            // Now you can create the short string
            let shortString = (text as NSString).substring(with: stringRange)
            
            let newText = NSMutableString()
            newText.append(oldString)
            newText.insert(shortString, at: range.location)
            textView.text = newText as String
            
            showCharactersNumberError()
            textViewDidChange(textView)
            
            return false
        }
        
        return true
    }
    
    override func textViewDidEndEditing(_ textView: UITextView) {
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
