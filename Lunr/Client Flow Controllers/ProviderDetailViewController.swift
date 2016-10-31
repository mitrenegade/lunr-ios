import UIKit

class ProviderDetailViewController : UIViewController {

    @IBOutlet weak var callButton: LunrActivityButton!
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
        //self.chatWithProvider(provider)
        // TEST
        self.testGoToFeedback()
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
            SessionService.sharedInstance.startChatWithUser(user, completion: { (success, dialog) in
                guard success else {
                    print("Could not start chat")
                    self?.simpleAlert("Could not start chat", defaultMessage: "There was an error starting a chat with this provider", error: nil, completion: nil)
                    return
                }
                
                if let chatNavigationVC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("ClientChatNavigationController") as? UINavigationController,
                    let chatVC = chatNavigationVC.viewControllers[0] as? ClientChatViewController {
                    chatVC.dialog = dialog
                    chatVC.providerId = self?.provider?.objectId
                    self?.presentViewController(chatNavigationVC, animated: true, completion: {
                        self?.callButton.busy = false
                        QBNotificationService.sharedInstance.currentDialogID = dialog?.ID!
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
            let controller = UIStoryboard(name: "CallFlow", bundle: nil).instantiateViewControllerWithIdentifier("FeedbackViewController") as? FeedbackViewController
            controller?.call = call
            self?.navigationController?.pushViewController(controller!, animated: true)
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
