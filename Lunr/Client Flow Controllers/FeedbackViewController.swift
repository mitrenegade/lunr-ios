import UIKit
import Parse

class FeedbackViewController: UITableViewController, StarRatingViewDelegate {

    @IBOutlet weak var closeButton: UIBarButtonItem!

    // Call Summary
    var call: Call?
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    // Experience Rating
    @IBOutlet weak var starRatingView: StarRatingView!
    var experienceRating : Int = 5

    // Feedback
    @IBOutlet weak var feedbackTextView: UITextView!
    @IBOutlet var feedbackToolbar: UIToolbar!
    @IBOutlet weak var leaveFeedbackBarButtonItem: UIBarButtonItem!

    // MARK: UIViewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateCall()
        
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

    func updateCall() {
        guard let call = self.call else { return }
        guard let start = call.date else { return }
        guard let rate = call.rate as? Double else { return }
        
        let duration = NSDate().timeIntervalSinceDate(start)
        let minutes = duration / 60
        
        call.duration = duration
        call.totalCost = minutes * rate
        // save the call
        if let user = PFUser.currentUser() as? User where user.isProvider {
            call.saveInBackgroundWithBlock({ (success, error) in
                if let _ = error {
                    // TODO: store total cost into another object
                    self.simpleAlert("Could not save call", message: "There was an error saving this call. Please let us know") {
                    }
                }
                else {
                    self.configureCallUI()
                }
            })
        }
        else {
            self.configureCallUI()
        }
    }

    func configureCallUI() {
        guard let call = call else { return }
        guard let _ = call.totalCost as? Double else {
            costLabel.text = "Calculating total cost..."
            durationLabel.text = nil
            return
        }
        
        self.durationLabel.text = "Time: \(call.totalDurationString)"
        if let user = PFUser.currentUser() as? User where user.isProvider {
            self.costLabel.text = "Cost: \(call.totalCostString)"
        }
        else {
            self.costLabel.text = "Est. Cost: \(call.totalCostString)"
        }
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
