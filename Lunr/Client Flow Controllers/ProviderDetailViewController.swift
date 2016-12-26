//
//  ProviderDetailViewController
//  Lunr
//
//  Created by Bobby Ren
//  Copyright © 2016 RenderApps. All rights reserved.
//

import UIKit
import Parse
import Stripe

class ProviderDetailViewController : UIViewController {

    @IBOutlet weak var callButton: LunrActivityButton!
    @IBOutlet weak var tableView: UITableView!

    var provider : User?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setUpTableView()
        setupCallButton()
        setUpNavigationBar()

        if let user = provider {
            // fetch in case object has not downloaded; prevents crash
            self.title = user.displayString
            if user.reviews == nil {
                // only load reviews if none exist
                self.refreshFeedback()
            }
        }
        self.listenFor(.FeedbackUpdated, action: #selector(refreshFeedback), object: nil)
        self.listenFor(.ProvidersUpdated, action: #selector(refreshProvider), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.navigationBar.tintColor = UIColor.lunr_darkBlue()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.backgroundColor = UIColor.lunr_iceBlue()
    }

    deinit {
        self.stopListeningFor(.FeedbackUpdated)
    }
    
    func setUpTableView() {
        self.tableView.register(UINib(nibName: "DetailTableViewCell", bundle: nil), forCellReuseIdentifier: "DetailTableViewCell")
        self.tableView.register(UINib(nibName: "ReviewTableViewCell", bundle: nil), forCellReuseIdentifier: "ReviewTableViewCell")

        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.separatorStyle = .singleLine
        self.tableView.backgroundColor = UIColor.lunr_iceBlue()
    }

    func setUpNavigationBar() {
        let backButton = UIBarButtonItem(image: UIImage.init(named: "back-arrow"), style: .plain, target: self, action: #selector(backWasPressed))
        self.navigationItem.leftBarButtonItem = backButton;
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont.futuraMediumWithSize(19)]
    }

    func setupCallButton() {
        self.callButton.setTitleColor(.white, for: UIControlState())
        self.callButton.backgroundColor = UIColor(red: 46/255, green: 56/255, blue: 91/255, alpha: 1.0)
        if let provider = self.provider, provider.available {
            self.callButton.setTitle("Send a message", for: UIControlState())
            self.callButton.isUserInteractionEnabled = true
            self.callButton.alpha = 1
        }
        else {
            self.callButton.setTitle("Currently unavailable", for: UIControlState())
            self.callButton.isUserInteractionEnabled = false
            self.callButton.alpha = 0.5
        }
    }
    
    func refreshFeedback() {
        guard let user = provider else { return }
        UserService.sharedInstance.queryReviewsForProvider(user, completionHandler: {[weak self]  (reviews) in
            user.reviews = reviews
            self?.tableView.reloadData()
            
            }, errorHandler: {[weak self]  (error) in
                self?.simpleAlert("Could not load reviews", defaultMessage: "There was an error loading reviews for this provider", error: error, completion: nil)
        })
    }

    func refreshProvider(notification: NSNotification) {
        guard let userInfo = notification.userInfo, let updated = userInfo["provider"] as? User else { return }
        if provider?.objectId == updated.objectId {
            // updates if available changes
            provider?.available = updated.available
            self.tableView.reloadData()
            self.setupCallButton()
        }
    }
    
    // MARK: Event Methods

    @IBAction func callButtonTapped(_ sender: AnyObject) {
        guard let provider = self.provider else { return }
        
        guard let currentUser = PFUser.current() as? User, currentUser.hasCreditCard() else {
            let title = "No credit card available"
            let message = "You must add a payment method before contacting a provider"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Add Credit Card", style: .default, handler: { (action) in
                self.showAccountSettings()
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        let connected = QBChat.instance().isConnected
        print("connected: \(connected)")
        
        self.callButton.busy = true
        QBUserService.sharedInstance.refreshUserSession { (success) in
            if success {
                print("Let's message \(self.provider?.displayString) on channel \(provider.objectId!)")
                self.chatWithProvider(provider)
            }
            else {
                self.callButton.busy = false
                var message = "Please log out and log in again"
                if QBUserService.sharedInstance.isRefreshingSession {
                    message = "Chat service seems to be temporarily available."
                }
                self.simpleAlert("Could not start chat", defaultMessage: message, error: nil, completion: nil)
            }
        }
    }

    func backWasPressed() {
        self.navigationController?.popToRootViewController(animated: true)
    }

    func showAccountSettings() {
        let controller = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "AccountSettingsViewController") as! AccountSettingsViewController
        let nav = UINavigationController(rootViewController: controller)
        self.navigationController?.present(nav, animated: true, completion: nil)
    }
    
    
}

extension ProviderDetailViewController {
    func chatWithProvider(_ provider: User) {
        self.callButton.busy = true
        QBUserService.getQBUUserFor(provider) { [weak self] user in
            guard let user = user else {
                // this can happen if the PFUser has not actually been set up on QuickBlox, or was deleted from quickBlox.
                let name = provider.displayString ?? "This provider"
                self?.simpleAlert("Could not start chat", defaultMessage: "\(name) cannot receive chat messages.", error: nil, completion: nil)
                
                self?.callButton.busy = false
                return
            }
            guard let clientId = PFUser.current()?.objectId else { return }
            
            // create/load the dialog on QuickBlox
            SessionService.sharedInstance.startChatWithUser(user, completion: { (success, dialog) in
                self?.callButton.busy = false
                guard success, let dialog = dialog else {
                    print("Could not start chat")
                    self?.simpleAlert("Could not start chat", defaultMessage: "There was an error starting a chat with this provider", error: nil, completion: nil)
                    
                    return
                }
                
                // create the conversation object on Parse, and notify
                let params = ["providerId": provider.objectId, "dialogId": dialog.id]
                PFCloud.callFunction(inBackground: "postNewConversation", withParameters: params) { [weak self] (results, error) in
                    if let conversation = results as? Conversation {
                        self?.goToChat(dialog: dialog, conversation: conversation)

                        /*
                         // PUSH FAILURE
                        self?.testAlert("Push notification failed", message: "Unable to send a push notification. However, the provider can still see this message if they are online.", type: .ClientPushNotificationFailed, error: nil, params: ["dialogId": dialog.id, "clientId": clientId], completion: {
                            self?.goToChat(dialog: dialog, conversation: conversation)
                        })
                        */
                    }
                    else {
                        // CONVERSATION SAVE FAILURE
                        self?.testAlert("Could not create conversation", message: "We could not start a chat conversation.", type: .ConversationSaveFailed, error: nil, params: ["dialogId": dialog.id ?? "", "clientId": clientId], completion: nil)
                    }
                }
            })
        }
    }
    
    func goToChat(dialog: QBChatDialog, conversation: Conversation) {
        if let chatNavigationVC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ClientChatNavigationController") as? UINavigationController,
            let chatVC = chatNavigationVC.viewControllers[0] as? ClientChatViewController {
            chatVC.dialog = dialog
            chatVC.provider = self.provider
            chatVC.conversation = conversation
            
            self.present(chatNavigationVC, animated: true, completion: {
                QBNotificationService.sharedInstance.currentDialogID = dialog.id!
            })
        }
    }
    
    func notifyForChat(_ user: QBUUser, _ dialogId: String, completion: @escaping (()->Void)) {
        //guard let timestamp = lastNotificationTimestamp where NSDate().timeIntervalSinceDate(timestamp) > kMinNotificationInterval else { return }
        guard let currentUser = PFUser.current() as? User else { return }
        let name = currentUser.displayString 
        
        let message = "\(name) wants to send you a message"
        let userInfo = ["dialogId": dialogId, "pfUserId": currentUser.objectId ?? "", "chatStatus": "invited"]
        
        PushService().sendNotificationToQBUser(user, message: message, userInfo: userInfo) { (success, error) in
            if success {
                completion()
                return
            }
            else {
                let qbError = error!
                // TODO: use qbError.reason when QuickBlox fixes their crash
                self.testAlert("Push notification failed", message: "Unable to send a push notification. However, the provider can still see this message if they are online.", type: .ClientPushNotificationFailed, error: nil, params: ["dialogId": dialogId, "name": name], completion: {
                    completion()
                })
            }
        }
    }

    // TEST
    func testGoToFeedback() {
        guard let provider = self.provider, let pfUserId = provider.objectId else {
            print("Invalid provider")
            return
        }
        
        CallService.sharedInstance.postNewCall(pfUserId, duration: 0, totalCost: 0) { [weak self] (call, error) in
            let controller = UIStoryboard(name: "CallFlow", bundle: nil).instantiateViewController(withIdentifier: "FeedbackViewController") as? FeedbackViewController
            controller?.call = call
            self?.navigationController?.pushViewController(controller!, animated: true)
        }
    }
}

extension ProviderDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let provider = self.provider else { return 0 }
        if section == 0 {
            return 1
        }
        guard let reviews = provider.reviews else { return 0 }
        return reviews.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell: DetailTableViewCell = tableView.dequeueReusableCell(withIdentifier: "DetailTableViewCell", for: indexPath) as! DetailTableViewCell
            cell.configureForProvider(self.provider!)
            return cell
        }
        let cell: ReviewTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ReviewTableViewCell", for: indexPath) as! ReviewTableViewCell
        if let reviews = self.provider?.reviews {
            cell.configureForReview(reviews[indexPath.row])
        }
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        headerView.backgroundView?.backgroundColor = UIColor.lunr_iceBlue()
        headerView.textLabel?.font = UIFont.futuraMediumWithSize(16)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? nil : "Reviews:"
    }
}
