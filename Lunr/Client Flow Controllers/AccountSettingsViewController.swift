//
//  AccountSettingsViewController.swift
//  Lunr
//
//  Created by Randall Spence on 8/21/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Stripe
import Parse

private let NumberOfSectionsInTableView = 3
private let SectionTitles = ["Account Information", "Payment Information", "Call History"]
private let AccountInfoSectionTitles = ["Email:", "Name:"]
private let PaymentInfoSectionTitles = ["Default:"]

class AccountSettingsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var callHistory: [Call]?
    var user: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = false
        self.navigationController?.navigationBar.backgroundColor = .whiteColor()
        self.navigationController?.navigationBar.tintColor = .lunr_darkBlue()
        self.navigationController?.navigationBar.addShadow()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .Plain, target: self, action: #selector(dismiss))
        
        self.user = PFUser.currentUser() as? User
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 140

        self.tableView.separatorStyle = .None

        UIApplication.sharedApplication().statusBarStyle = .LightContent

        self.refresh()
        self.listenFor(NotificationType.FeedbackUpdated, action: #selector(refresh), object: nil)
    }

    func dismiss() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    func refresh() {
        CallService.sharedInstance.queryCallsForUser(self.user) { [weak self] (results, error) in
            print("refreshing account settings")
            print("results: \(results)")
            self?.callHistory = results
            self?.tableView.reloadData()
        }
    }
    
    deinit {
        self.stopListeningFor(NotificationType.FeedbackUpdated)
    }
    
    func showAccountInfo() {
        let controller = UIStoryboard(name: "Settings", bundle: nil).instantiateViewControllerWithIdentifier("EditAccountSettingsViewController") as! EditAccountSettingsViewController
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func showPaymentInfo() {
        // Placeholder
        
        let addCardViewController = STPAddCardViewController()
        addCardViewController.delegate = self
        // STPAddCardViewController must be shown inside a UINavigationController.
        let navigationController = UINavigationController(rootViewController: addCardViewController)
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
}

extension AccountSettingsViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        switch section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("AccountInfoCell", forIndexPath: indexPath) as! AccountInfoCell
            cell.detailLabel.text = AccountInfoSectionTitles[row]
            switch row {
                case 0:
                cell.textField.text = user?.email
                cell.textField.secureTextEntry = false
                cell.textField.placeholder = "add your email"
            case 1:
                cell.textField.text = user?.displayString
                cell.textField.secureTextEntry = false
                cell.textField.placeholder = "add your name"
            default:
                return UITableViewCell()
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("AccountInfoCell", forIndexPath: indexPath) as! AccountInfoCell
            cell.detailLabel.text = PaymentInfoSectionTitles[row]
            cell.textField.text = StripeService().paymentStringForUser(self.user)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("CallHistoryCell", forIndexPath: indexPath) as! ClientCallHistoryCell
            guard let calls = self.callHistory where row < calls.count else {
                return cell
            }
            let call = calls[row]
            cell.configure(call)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0 : return AccountInfoSectionTitles.count
        case 1 : return PaymentInfoSectionTitles.count
        case 2 : return callHistory?.count ?? 0
        default: return 0
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return NumberOfSectionsInTableView
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return SectionTitles[section]
    }
}

extension AccountSettingsViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Placeholder
        print("did select")
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        guard let calls = self.callHistory where indexPath.row < calls.count else {
            return
        }
        
        let call = calls[indexPath.row]
        let controller = UIStoryboard(name: "CallFlow", bundle: nil).instantiateViewControllerWithIdentifier("FeedbackViewController") as? FeedbackViewController
        controller?.call = call
        controller?.existingFeedback = call.review
        self.navigationController?.pushViewController(controller!, animated: true)        
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let section = indexPath.section
        if section == 2 {
            return 100
        }
        return 35
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRectMake(0, 0, tableView.bounds.size.width, 50))
        let label = UILabel(frame: CGRectMake(16, 20, tableView.bounds.size.width, 20))
        let attributes = [NSFontAttributeName : UIFont(name: "Futura-Medium", size: 16)!]
        let attributedText = NSAttributedString(string: SectionTitles[section], attributes: attributes)
        label.attributedText = attributedText
        headerView.backgroundColor = .whiteColor()
        headerView.addSubview(label)
        return headerView
    }

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section != 2 else {
            return UIView(frame: CGRectZero)
        }
        let footerView = UIView(frame: CGRectMake(0, 0, tableView.bounds.size.width, 80))
        let button = UIButton(frame: CGRectMake(16, 0, tableView.bounds.size.width, 30))
        button.setTitleColor(.lunr_darkBlue(), forState: .Normal)
        button.contentHorizontalAlignment = .Left
        let underlineAttribute = [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue, NSFontAttributeName : UIFont(name: "Futura-Medium", size: 13)!]

        if section == 0 {
            let underlineAttributedString = NSAttributedString(string: "Edit Account Information", attributes: underlineAttribute)
            button.setAttributedTitle(underlineAttributedString, forState: .Normal)
            button.addTarget(self, action: #selector(showAccountInfo), forControlEvents: .TouchUpInside)
        } else if section == 1 {
            let underlineAttributedString = NSAttributedString(string: "Edit Payment Information", attributes: underlineAttribute)
            button.setAttributedTitle(underlineAttributedString, forState: .Normal)
            button.addTarget(self, action: #selector(showPaymentInfo), forControlEvents: .TouchUpInside)
        }
        footerView.addSubview(button)
        return footerView
    }
}

extension AccountSettingsViewController: STPAddCardViewControllerDelegate {
    func addCardViewControllerDidCancel(addCardViewController: STPAddCardViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func addCardViewController(addCardViewController: STPAddCardViewController, didCreateToken token: STPToken, completion: STPErrorBlock) {

        guard let user = PFUser.currentUser() as? User else { return }
        StripeService().postNewPayment(user, token: token) { (result, error) in
            print("\(result) \(error)")
            if let error = error {
                self.simpleAlert("Could not add card", defaultMessage: "There was an issue adding your credit card", error: error, completion: { 
                    // nothing
                })
            }
            else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            completion(error)
        }
    }
}
