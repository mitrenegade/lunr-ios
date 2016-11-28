import UIKit
import Parse
import ParseLiveQuery

class ProviderListViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, SortCategoryProtocol {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var sortCategoryView: SortCategoryView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var providers: [User]?
    var currentSortCategory: SortCategory = .none
    var searchTerms: [String] = []
    
    // live query for Parse objects
    let liveQueryClient = ParseLiveQuery.Client()
    var subscription: Subscription<User>?

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTableView()
        let image = UIImage(imageLiteralResourceName: "search")
        self.searchBar.setImage(image, for: .search, state: UIControlState())
        self.sortCategoryView.delegate = self
        self.activityIndicator.tintColor = UIColor.lunr_darkBlue()
        
        // load cached sort category if user previously selected one
        if let cachedSortCategory = UserDefaults.standard.value(forKey: UserDefaultsKeys.SortCategory.rawValue) as? SortCategory.RawValue {
            let category = SortCategory(rawValue: cachedSortCategory)!
            self.sortCategoryView.highlightButtonForCategory(category) // update the view
            self.sortCategoryWasSelected(category) // make the query
        }
        else {
            let category = SortCategory.alphabetical
            self.sortCategoryView.highlightButtonForCategory(category) // update the view
            self.sortCategoryWasSelected(category) // make the query
        }
        
        // listen for changes
        self.subscribeToUpdates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.backgroundColor = UIColor.lunr_darkBlue()
    }

    func setUpTableView() {
        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.separatorStyle = .none
        self.tableView.showsVerticalScrollIndicator = false
    }
    
    func refreshProviders(_ page: Int) {
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

    func subscribeToUpdates() {
        if LOCAL_TEST {
            return
        }
        
        guard let user = PFUser.current(), let userId = user.objectId else { return }
        guard let query: PFQuery<User> = PFUser.query() as? PFQuery<User> else { return }
        query.whereKey("type", containedIn:[UserType.Plumber.rawValue.lowercased(), UserType.Electrician.rawValue.lowercased(), UserType.Handyman.rawValue.lowercased()])
        
        self.subscription = liveQueryClient.subscribe(query)
            .handle(Event.updated, { (_, object) in
                if let providers = self.providers {
                    var changed = false
                    for user in providers {
                        if user.objectId == object.objectId, let index = providers.index(of: user) {
                            self.providers!.remove(at: index)
                            self.providers!.insert(object, at: index)
                            changed = true
                        }
                    }
                    if changed {
                        DispatchQueue.main.async(execute: {
                            print("received update for provider: \(object.objectId!)")
                            self.tableView.reloadData()
                        })
                    }
                }
            })
    }

    // MARK: Event Methods

    @IBAction func settingsButtonPressed(_ sender: UIBarButtonItem) {
        // TODO: show the settings
        self.searchBar.resignFirstResponder()

        print("showSettings")
        let controller = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "AccountSettingsViewController") as! AccountSettingsViewController
        let nav = UINavigationController(rootViewController: controller)
        self.navigationController?.present(nav, animated: true, completion: nil)
    }

    // MARK: SortCategoryProtocol Methods

    func sortCategoryWasSelected(_ sortCategory: SortCategory) {
        // make request for providers in the order specified by the sort category.
        self.searchBar.resignFirstResponder()

        guard sortCategory != currentSortCategory else { return }
        
        self.currentSortCategory = sortCategory
        self.refreshProviders(0)
        
        UserDefaults.standard.setValue(sortCategory.rawValue, forKey: UserDefaultsKeys.SortCategory.rawValue)
    }

    // MARK: UITableViewDelegate Methods

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.searchBar.resignFirstResponder()

        guard let providers = self.providers else { return }

        self.performSegue(withIdentifier: "GoToProviderDetail", sender: providers[indexPath.row])
    }

    // MARK: UITableViewDataSource Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let providers = self.providers else { return 0 }
        return providers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProviderTableViewCell") as! ProviderTableViewCell
        if let providers = self.providers {
            cell.configureForProvider(providers[indexPath.row])
        }
        return cell
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToProviderDetail" {
            if let providerDetails = segue.destination as? ProviderDetailViewController, let user = sender as? User {
                providerDetails.configureForProvider(user)
            }
        }
    }
    
    // MARK: Search bar
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
        self.view.endEditing(true)
        guard let text = searchBar.text else { return }
        print("Searching for \(text)")
        
        searchTerms = text.characters.split(separator: " ").map(String.init)
        self.refreshProviders(0)
    }
}

