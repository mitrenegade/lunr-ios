//
//  FeedbackViewController.swift
//  Lunr
//
//  Created by Amy Ly on 9/4/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class FeedbackViewController: UITableViewController {

    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var feedbackTextView: UITextView!
    @IBOutlet weak var closeButton: UIBarButtonItem!
    @IBOutlet var feedbackToolbar: UIToolbar!
    @IBOutlet weak var leaveFeedbackBarButtonItem: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.leaveFeedbackBarButtonItem.setTitleTextAttributes(
            [NSFontAttributeName : UIFont.futuraMediumWithSize(16)], forState: .Normal
        )
        self.feedbackToolbar.barTintColor = UIColor.lunr_darkBlue()
        self.feedbackTextView.inputAccessoryView = self.feedbackToolbar

        self.closeButton.tintColor = UIColor.lunr_darkBlue()
        self.tableView.backgroundColor = UIColor.lunr_iceBlue()
        self.title = "Call Feedback"
    }

    func configureForCall(call: Call) {
        self.durationLabel.text = "\(call.duration)"
        self.costLabel.text = "\(call.totalCost)"
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.backgroundColor = UIColor.lunr_iceBlue()
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont.futuraMediumWithSize(17)]
        self.navigationController?.navigationBar.addShadow()
    }

    @IBAction func closedButtonPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        headerView.backgroundView?.backgroundColor = UIColor.lunr_iceBlue()
        headerView.textLabel?.font = UIFont.futuraMediumWithSize(16)
    }
}
