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
        
        QBUserService.sharedInstance.refreshUserSession { (success) in
            if success {
                print("Let's message \(self.provider?.displayString) on channel \(provider.objectId!)")
                self.chatWithProvider(provider)
            }
            else {
                self.simpleAlert("Could not start chat", defaultMessage: "Please log out and log in again", error: nil, completion: nil)
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
            SessionService.sharedInstance.startChatWithUser(user, completion: { (success, dialog) in
                guard success else {
                    print("Could not start chat")
                    self?.simpleAlert("Could not start chat", defaultMessage: "There was an error starting a chat with this provider", error: nil, completion: nil)
                    
                    return
                }
                
                if let chatNavigationVC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ClientChatNavigationController") as? UINavigationController,
                    let chatVC = chatNavigationVC.viewControllers[0] as? ClientChatViewController {
                    chatVC.dialog = dialog
                    chatVC.providerId = self?.provider?.objectId
                    self?.present(chatNavigationVC, animated: true, completion: {
                        self?.callButton.busy = false
                        QBNotificationService.sharedInstance.currentDialogID = dialog?.id!
                    })
                }
            })
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
