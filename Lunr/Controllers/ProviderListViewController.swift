import UIKit

class ProviderListViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, SortCategoryProtocol {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var sortCategoryView: SortCategoryView!
    var providers: [Provider] = //TODO: remove these dummy providers
        [Provider(
            name: "John Snow",
            rating: 5.0,
            reviews: [],
            ratePerMin: 4.3,
            skills: ["Raiding", "Leadership"],
            info: "John Snow is the son of Rhaegar and Lyanna. Oops that was a spoiler! Well, that's your fault cause you should be caught up on the show..."),
         Provider(
            name: "John Snow",
            rating: 5.0,
            reviews:
            [
                Review(rating: 4.0, text: "this guy is good"),
                Review(rating: 3.3, text: "John Snow is the son of Rhaegar and Lyanna. Oops that was a spoiler! Well, that's your fault cause you should be caught up on the show...")
            ],
            ratePerMin: 4.3,
            skills: ["Raiding", "Leadership"],
            info: "oh hello")]

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTableView()
        self.searchBar.setImage(UIImage(imageLiteral: "search"), forSearchBarIcon: .Search, state: .Normal)
        self.sortCategoryView.delegate = self
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
        let controller = UIStoryboard(name: "Randall", bundle: nil).instantiateViewControllerWithIdentifier("AccountSettingsViewController") as! AccountSettingsViewController
        self.navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: SortCategoryProtocol Methods

    func sortCategoryWasSelected(sortCategory: SortCategory) {
        // TODO: make request for providers in the order specified by the sort category.
    }

    // MARK: UITableViewDelegate Methods

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let providerDetails = UIStoryboard(name: "Randall", bundle: nil).instantiateViewControllerWithIdentifier("ProviderDetailViewController") as? ProviderDetailViewController {
            providerDetails.configureForProvider(self.providers[indexPath.row])
            self.navigationController?.pushViewController(providerDetails, animated: true)
        }
    }

    // MARK: UITableViewDataSource Methods

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return providers.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ProviderTableViewCell") as! ProviderTableViewCell
        cell.configureForProvider(providers[indexPath.row])
        return cell
    }
}

