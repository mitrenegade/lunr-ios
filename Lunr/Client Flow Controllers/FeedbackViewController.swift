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
    
    // Existing feedback
    weak var existingFeedback: Review?

    @IBOutlet weak var buttonSave: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureUI()

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
    
    func configureUI() {
        guard let call = call else { return }
        
        self.durationLabel.text = "Time: \(call.totalDurationString)"
        if let user = PFUser.currentUser() as? User where user.isProvider {
            self.costLabel.text = "Est. Payment: \(call.totalCostString)"
        }
        else {
            self.costLabel.text = "Est. Cost: \(call.totalCostString)"
        }
        
        if let feedback = self.existingFeedback {
            self.starRatingView.userInteractionEnabled = false
            self.starRatingView.currentRating = Int(feedback.rating)
            self.feedbackTextView.text = feedback.text
        }
    }
    
    // MARK: Event Methods
    func dismiss() {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func close(sender: AnyObject) {
        guard self.call != nil else {
            self.dismiss()
            return
        }
        
        if let user = PFUser.currentUser() as? User where user.isProvider {
            self.dismiss()
            return
        }
        
        let alert = UIAlertController(title: "Feedback?", message: "You haven't rated your call. Are you sure you want to leave without giving feedback?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action) in
            self.dismiss()
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
        guard let call = self.call else {
            self.dismiss()
            return
        }

        if let user = PFUser.currentUser() as? User where user.isProvider {
            self.dismiss()
            return
        }

        if self.starRatingView.currentRating == 0 {
            // return to star rating
            self.feedbackTextView.resignFirstResponder()
            self.simpleAlert("Please include rating", defaultMessage: "Reviews must include a star rating.", error: nil, completion: { 
                // nothing
            })
        }
        else {
            // create feedback
            print("Thanks for your feedback! \(self.starRatingView.currentRating) stars: \(feedbackTextView.text)")
            if let feedback = self.existingFeedback {
                feedback.text = self.feedbackTextView.text
                feedback.saveInBackgroundWithBlock({ (success, error) in
                    if let error = error {
                        print("error")
                        self.simpleAlert("Error updating feedback", defaultMessage: "Your feedback was not updated. Please try again.", error: error, completion: {
                            self.dismiss()
                        })
                    }
                    else {
                        print("review posted")
                        self.notify(NotificationType.FeedbackUpdated)
                        self.dismiss()
                    }
                })
            }
            else {
                ReviewService.sharedInstance.postReview(call, rating: Double(self.starRatingView.currentRating), feedback: self.feedbackTextView.text, completion: { (review, error) in
                    if let error = error {
                        print("error")
                        self.simpleAlert("Error submitting feedback", defaultMessage: "You can try again later from your call history", error: error, completion: {
                            self.dismiss()
                        })
                    }
                    else {
                        print("review posted")
                        self.notify(NotificationType.FeedbackUpdated)
                        self.dismiss()
                    }
                })
            }
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
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // do not show feedback for providers
        if let user = PFUser.currentUser() as? User where user.isProvider {
            return 1
        }
        return 3
    }
}
