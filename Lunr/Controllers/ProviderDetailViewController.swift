import UIKit

class ProviderDetailViewController : UIViewController {

    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var callButtonView: UIView!
    @IBOutlet weak var tableView: UITableView!

    var provider : User?

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTableView()
        setupCallButton()
        setUpNavigationBar()
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
        print("Let's call \(self.provider?.displayString)")
    }

    func backWasPressed() {
        self.navigationController?.popToRootViewControllerAnimated(true)
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
