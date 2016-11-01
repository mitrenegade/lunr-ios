import UIKit

class ProviderListViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, SortCategoryProtocol {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var sortCategoryView: SortCategoryView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var providers: [User]?
    var currentSortCategory: SortCategory = .None
    var searchTerms: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTableView()
        self.searchBar.setImage(UIImage(imageLiteral: "search"), forSearchBarIcon: .Search, state: .Normal)
        self.sortCategoryView.delegate = self
        self.activityIndicator.tintColor = UIColor.lunr_darkBlue()
        
        // load cached sort category if user previously selected one
        if let cachedSortCategory = NSUserDefaults.standardUserDefaults().valueForKey(UserDefaultsKeys.SortCategory.rawValue) as? SortCategory.RawValue {
            let category = SortCategory(rawValue: cachedSortCategory)!
            self.sortCategoryView.highlightButtonForCategory(category) // update the view
            self.sortCategoryWasSelected(category) // make the query
        }
        else {
            let category = SortCategory.Alphabetical
            self.sortCategoryView.highlightButtonForCategory(category) // update the view
            self.sortCategoryWasSelected(category) // make the query
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
        self.tableView.showsVerticalScrollIndicator = false
    }
    
    func refreshProviders(page: Int) {
        self.activityIndicator.startAnimating()
        UserService.sharedInstance.queryProvidersAtPage(page, filterOption: currentSortCategory, searchTerms: searchTerms, ascending: true, availableOnly: false, completionHandler: {[weak self] (providers) in
            self?.activityIndicator.stopAnimating()
            self?.providers = providers as? [User]
            self?.tableView.reloadData()
        }) {[weak self]  (error) in
            self?.activityIndicator.stopAnimating()
            print("Error loading providers: \(error)")
            self?.simpleAlert("Could not load providers", defaultMessage: "There was an error loading available providers.", error: error, completion: nil)
        }
    }

    // MARK: Event Methods

    @IBAction func settingsButtonPressed(sender: UIBarButtonItem) {
        // TODO: show the settings
        self.searchBar.resignFirstResponder()

        print("showSettings")
        let controller = UIStoryboard(name: "Settings", bundle: nil).instantiateViewControllerWithIdentifier("AccountSettingsViewController") as! AccountSettingsViewController
        let nav = UINavigationController(rootViewController: controller)
        self.navigationController?.presentViewController(nav, animated: true, completion: nil)
    }

    // MARK: SortCategoryProtocol Methods

    func sortCategoryWasSelected(sortCategory: SortCategory) {
        // make request for providers in the order specified by the sort category.
        self.searchBar.resignFirstResponder()

        guard sortCategory != currentSortCategory else { return }
        
        self.currentSortCategory = sortCategory
        self.refreshProviders(0)
        
        NSUserDefaults.standardUserDefaults().setValue(sortCategory.rawValue, forKey: UserDefaultsKeys.SortCategory.rawValue)
    }

    // MARK: UITableViewDelegate Methods

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.searchBar.resignFirstResponder()

        guard let providers = self.providers else { return }

        self.performSegueWithIdentifier("GoToProviderDetail", sender: providers[indexPath.row])
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
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GoToProviderDetail" {
            if let providerDetails = segue.destinationViewController as? ProviderDetailViewController, let user = sender as? User {
                providerDetails.configureForProvider(user)
            }
        }
    }
    
    // MARK: Search bar
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
        self.view.endEditing(true)
        guard let text = searchBar.text else { return }
        print("Searching for \(text)")
        
        searchTerms = text.characters.split(" ").map(String.init)
        self.refreshProviders(0)
    }
}

