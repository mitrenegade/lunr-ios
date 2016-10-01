import UIKit

class ProviderDetailViewController : UIViewController {

    @IBOutlet weak var callButton: LunrActivityButton!
    @IBOutlet weak var callButtonView: UIView!
    @IBOutlet weak var tableView: UITableView!

    var provider : User?

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTableView()
        setupCallButton()
        setUpNavigationBar()

        if let user = provider where user.reviews == nil {
            // only load reviews if none exist

            UserService.sharedInstance.queryReviewsForProvider(user, completionHandler: {[weak self]  (reviews) in
                user.reviews = reviews
                self?.tableView.reloadData()

                }, errorHandler: {[weak self]  (error) in
                    self?.simpleAlert("Could not load reviews", defaultMessage: "There was an error loading reviews for this provider", error: error, completion: nil)
            })
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.navigationBar.tintColor = UIColor.lunr_darkBlue()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.backgroundColor = UIColor.lunr_iceBlue()
    }

    func configureForProvider(provider: User) {
        self.provider = provider
        self.title = provider.displayString
    }

    func setUpTableView() {
        self.tableView.registerNib(UINib(nibName: "DetailTableViewCell", bundle: nil), forCellReuseIdentifier: "DetailTableViewCell")
        self.tableView.registerNib(UINib(nibName: "ReviewTableViewCell", bundle: nil), forCellReuseIdentifier: "ReviewTableViewCell")

        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.separatorStyle = .SingleLine
        self.tableView.backgroundColor = UIColor.lunr_iceBlue()
    }

    func setUpNavigationBar() {
        let backButton = UIBarButtonItem(image: UIImage.init(named: "back-arrow"), style: .Plain, target: self, action: #selector(backWasPressed))
        self.navigationItem.leftBarButtonItem = backButton;
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont.futuraMediumWithSize(19)]
    }

    func setupCallButton() {
        // TODO: Localize
        // TODO: Change to attributed title when the font is added
        self.callButton.setTitle("Call Now", forState: .Normal)
        self.callButton.setTitleColor(.whiteColor(), forState: .Normal)
        // TODO: Move to theme file or UIAppearance Proxy
        self.callButton.backgroundColor = UIColor(red: 46/255, green: 56/255, blue: 91/255, alpha: 1.0)
    }

    // MARK: Event Methods

    @IBAction func callButtonTapped(sender: AnyObject) {
        guard let provider = self.provider else { return }
        print("Let's call \(self.provider?.displayString) on channel \(provider.objectId!)")

        /*
         // PLACEHOLDER: go to ChatPlaceholderViewController, then go to Call
        if let controller = UIStoryboard(name: "CallFlow", bundle: nil).instantiateViewControllerWithIdentifier("ChatPlaceholderViewController") as? ChatPlaceholderViewController {
            controller.targetUser = self.provider
            self.navigationController?.pushViewController(controller, animated: true)
        }
        */
        
        /*
         // PLACEHOLDER: go directly to CallViewController
        if let controller = UIStoryboard(name: "CallFlow", bundle: nil).instantiateViewControllerWithIdentifier("CallViewController") as? CallViewController {
            controller.targetPFUser = self.provider
            self.navigationController?.pushViewController(controller, animated: true)
        }
        */
        
        // PLACEHOLDER: send a push notification to the given provider
        /*
        PushService().sendNotificationToUser(provider) { (success, error) in
            if success {
                self.simpleAlert("Push sent!", message: "You have successfully notified \(self.provider!.displayString) to chat")
            }
            else {
                self.simpleAlert("Could not send push", defaultMessage: nil, error: nil)
            }
        }
        */
        self.chatWithProvider(provider)
    }

    func backWasPressed() {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
}

extension ProviderDetailViewController {
    func chatWithProvider(provider: User) {
        self.callButton.busy = true
        QBUserService.getQBUUserFor(provider) { [weak self] user in
            guard let user = user else { self?.callButton.busy = false; return }
            QBUserService.instance().usersService.usersMemoryStorage.addUser(user)
            QBUserService.instance().chatService.createPrivateChatDialogWithOpponent(user) { [weak self] response, dialog in
                self?.callButton.busy = false
                if let chatNavigationVC = UIStoryboard(name: "Chat", bundle: nil).instantiateInitialViewController() as? UINavigationController,
                    let chatVC = chatNavigationVC.viewControllers[0] as? ChatViewController {
                    chatVC.dialog = dialog
                    self?.presentViewController(chatNavigationVC, animated: true, completion: nil)
                }
            }
        }
    }

}

extension ProviderDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let provider = self.provider else { return 0 }
        if section == 0 {
            return 1
        }
        guard let reviews = provider.reviews else { return 0 }
        return reviews.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell: DetailTableViewCell = tableView.dequeueReusableCellWithIdentifier("DetailTableViewCell", forIndexPath: indexPath) as! DetailTableViewCell
            cell.configureForProvider(self.provider!)
            return cell
        }
        let cell: ReviewTableViewCell = tableView.dequeueReusableCellWithIdentifier("ReviewTableViewCell", forIndexPath: indexPath) as! ReviewTableViewCell
        if let reviews = self.provider?.reviews {
            cell.configureForReview(reviews[indexPath.row])
        }
        return cell
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        headerView.backgroundView?.backgroundColor = UIColor.lunr_iceBlue()
        headerView.textLabel?.font = UIFont.futuraMediumWithSize(16)
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? nil : "Reviews:"
    }
}
