import UIKit

class FeedbackViewController: UITableViewController, StarRatingViewDelegate {

    @IBOutlet weak var closeButton: UIBarButtonItem!

    // Call Summary
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    // Experience Rating
    @IBOutlet weak var starRatingView: StarRatingView!
    var experienceRating : Int = 5

    // Feedback
    @IBOutlet weak var feedbackTextView: UITextView!
    @IBOutlet var feedbackToolbar: UIToolbar!
    @IBOutlet weak var leaveFeedbackBarButtonItem: UIBarButtonItem!

    var call : Call?

    func configureCall() {
        if self.call != nil {
            self.durationLabel.text = "\(self.call!.duration)"
            self.costLabel.text = "\(self.call!.totalCost)"
        }
    }

    // MARK: UIViewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureCall();

        self.starRatingView.delegate = self

        self.leaveFeedbackBarButtonItem.setTitleTextAttributes(
            [NSFontAttributeName : UIFont.futuraMediumWithSize(16)], forState: .Normal
        )
        self.feedbackToolbar.barTintColor = UIColor.lunr_darkBlue()
        self.feedbackTextView.inputAccessoryView = self.feedbackToolbar
        self.feedbackTextView.layer.borderColor = UIColor.lunr_lightBlue().CGColor
        self.feedbackTextView.layer.borderWidth = 2.5

        self.closeButton.tintColor = UIColor.lunr_darkBlue()
        self.tableView.backgroundColor = UIColor.lunr_iceBlue()
        self.title = "Call Feedback"
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.backgroundColor = UIColor.lunr_iceBlue()
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont.futuraMediumWithSize(17)]
        self.navigationController?.navigationBar.addShadow()
    }


    // MARK: Event Methods

    @IBAction func closedButtonPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: StarRatingViewDelegate Methods

    func starRatingSelected(rating: Int) {
        self.experienceRating = rating

        //TODO: save the experience rating as a parameter in a request to update feedback
    }

    @IBAction func leaveFeedbackPressed(sender: UIBarButtonItem) {
        //TODO: handle leaving feedback
    }

    // MARK: UITableViewDelegate Methods

    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        headerView.backgroundView?.backgroundColor = UIColor.lunr_iceBlue()
        headerView.textLabel?.font = UIFont.futuraMediumWithSize(16)
        headerView.textLabel?.textColor = UIColor.blackColor()
        if let headerLabel = headerView.textLabel?.text {
            headerView.textLabel?.text = headerLabel.capitalizedString
        }
    }
}
