import UIKit
import Parse

class FeedbackViewController: UITableViewController, StarRatingViewDelegate {

    // Call Summary
    var call: Call?
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    // Experience Rating
    @IBOutlet weak var starRatingView: StarRatingView!

    // Feedback
    @IBOutlet weak var feedbackTextView: UITextView!
    @IBOutlet var feedbackToolbar: UIToolbar!

    // MARK: UIViewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureCallUI()

        self.starRatingView.delegate = self

        self.feedbackToolbar.barTintColor = UIColor.lunr_darkBlue()
        self.feedbackTextView.inputAccessoryView = self.feedbackToolbar
        self.feedbackTextView.layer.borderColor = UIColor.lunr_lightBlue().CGColor
        self.feedbackTextView.layer.borderWidth = 2.5

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
    
    func configureCallUI() {
        guard let call = call else { return }
        
        self.durationLabel.text = "Time: \(call.totalDurationString)"
        if let user = PFUser.currentUser() as? User where user.isProvider {
            self.costLabel.text = "Cost: \(call.totalCostString)"
        }
        else {
            self.costLabel.text = "Est. Cost: \(call.totalCostString)"
        }
    }
    
    // MARK: Event Methods

    @IBAction func close(sender: AnyObject) {
        let alert = UIAlertController(title: "Feedback?", message: "You haven't rated your call. Are you sure you want to leave without giving feedback?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action) in
            // close
            self.navigationController?.popToRootViewControllerAnimated(true)
        }))
        alert.addAction(UIAlertAction(title: "No, give feedback", style: .Cancel, handler: { (action) in
            // nothing
        }))
        self.navigationController?.presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: StarRatingViewDelegate Methods

    func starRatingSelected(rating: Int) {
        //TODO: save the experience rating as a parameter in a request to update feedback
    }

    @IBAction func save(sender: UIBarButtonItem) {
        if self.starRatingView.currentRating == 0 {
            // return to star rating
            self.feedbackTextView.resignFirstResponder()
        }
        else {
            // create feedback
            print("Thanks for your feedback! \(self.starRatingView.currentRating) stars: \(feedbackTextView.text)")
        }
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
