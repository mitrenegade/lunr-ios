import UIKit

class ProviderListViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, SortCategoryProtocol {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var sortCategoryView: SortCategoryView!
    var providers: [User]?

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTableView()
        self.searchBar.setImage(UIImage(imageLiteral: "search"), forSearchBarIcon: .Search, state: .Normal)
        self.sortCategoryView.delegate = self
        
        UserService.sharedInstance.queryProviders(false, completionHandler: {[weak self] (providers) in
            self?.providers = providers as? [User]
            self?.tableView.reloadData()
            }) {[weak self]  (error) in
                print("Error loading providers: \(error)")
                self?.simpleAlert("Could not load providers", defaultMessage: "There was an error loading available providers.", error: error, completion: nil)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.backgroundColor = UIColor.lunr_darkBlue()
    }

    func setUpTableView() {
        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.separatorStyle = .None
    }

    // MARK: Event Methods

    @IBAction func settingsButtonPressed(sender: UIBarButtonItem) {
        // TODO: show the settings
        print("showSettings")
        let controller = UIStoryboard(name: "Settings", bundle: nil).instantiateViewControllerWithIdentifier("AccountSettingsViewController") as! AccountSettingsViewController
        self.navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: SortCategoryProtocol Methods

    func sortCategoryWasSelected(sortCategory: SortCategory) {
        // TODO: make request for providers in the order specified by the sort category.
    }

    // MARK: UITableViewDelegate Methods

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        guard let providers = self.providers else { return }
        
        if let providerDetails = UIStoryboard(name: "Randall", bundle: nil).instantiateViewControllerWithIdentifier("ProviderDetailViewController") as? ProviderDetailViewController {
            providerDetails.configureForProvider(providers[indexPath.row])
            self.navigationController?.pushViewController(providerDetails, animated: true)
        }
    }

    // MARK: UITableViewDataSource Methods

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let providers = self.providers else { return 0 }
        return providers.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ProviderTableViewCell") as! ProviderTableViewCell
        if let providers = self.providers {
            cell.configureForProvider(providers[indexPath.row])
        }
        return cell
    }
}

