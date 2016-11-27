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
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.backgroundColor = .white
        self.navigationController?.navigationBar.tintColor = .lunr_darkBlue()
        self.navigationController?.navigationBar.addShadow()
        
        self.user = PFUser.current() as? User
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 140

        self.tableView.separatorStyle = .none

        UIApplication.shared.statusBarStyle = .lightContent

        self.refresh()
        self.listenFor(NotificationType.FeedbackUpdated, action: #selector(refresh), object: nil)
    }

    @IBAction func dismiss() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
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
        let controller = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "EditAccountSettingsViewController") as! EditAccountSettingsViewController
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func showPaymentInfo() {
        // Placeholder
        
        let addCardViewController = STPAddCardViewController()
        addCardViewController.delegate = self
        // STPAddCardViewController must be shown inside a UINavigationController.
        let navigationController = UINavigationController(rootViewController: addCardViewController)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    @IBAction func logout() {
        UserService.logout()
    }
}

extension AccountSettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        switch section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountInfoCell", for: indexPath) as! AccountInfoCell
            cell.detailLabel.text = AccountInfoSectionTitles[row]
            switch row {
                case 0:
                cell.textField.text = user?.email
                cell.textField.isSecureTextEntry = false
                cell.textField.placeholder = "add your email"
            case 1:
                cell.textField.text = user?.displayString
                cell.textField.isSecureTextEntry = false
                cell.textField.placeholder = "add your name"
            default:
                return UITableViewCell()
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AccountInfoCell", for: indexPath) as! AccountInfoCell
            cell.detailLabel.text = PaymentInfoSectionTitles[row]
            cell.textField.text = StripeService().paymentStringForUser(self.user)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CallHistoryCell", for: indexPath) as! ClientCallHistoryCell
            guard let calls = self.callHistory, row < calls.count else {
                return cell
            }
            let call = calls[row]
            cell.configure(call)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0 : return AccountInfoSectionTitles.count
        case 1 : return PaymentInfoSectionTitles.count
        case 2 : return callHistory?.count ?? 0
        default: return 0
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return NumberOfSectionsInTableView
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return SectionTitles[section]
    }
}

extension AccountSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Placeholder
        print("did select")
        tableView.deselectRow(at: indexPath, animated: true)
        guard let calls = self.callHistory, indexPath.row < calls.count else {
            return
        }
        
        let call = calls[indexPath.row]
        let controller = UIStoryboard(name: "CallFlow", bundle: nil).instantiateViewController(withIdentifier: "FeedbackViewController") as? FeedbackViewController
        controller?.call = call
        controller?.existingFeedback = call.review
        self.navigationController?.pushViewController(controller!, animated: true)        
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = indexPath.section
        if section == 2 {
            return 100
        }
        return 35
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 50))
        let label = UILabel(frame: CGRect(x: 16, y: 20, width: tableView.bounds.size.width, height: 20))
        let attributes = [NSFontAttributeName : UIFont(name: "Futura-Medium", size: 16)!]
        let attributedText = NSAttributedString(string: SectionTitles[section], attributes: attributes)
        label.attributedText = attributedText
        headerView.backgroundColor = .white
        headerView.addSubview(label)
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section != 2 else {
            return UIView(frame: CGRect.zero)
        }
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 80))
        let button = UIButton(frame: CGRect(x: 16, y: 0, width: tableView.bounds.size.width, height: 30))
        button.setTitleColor(.lunr_darkBlue(), for: UIControlState())
        button.contentHorizontalAlignment = .left
        let underlineAttribute = [NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue, NSFontAttributeName : UIFont(name: "Futura-Medium", size: 13)!] as [String : Any]

        if section == 0 {
            let underlineAttributedString = NSAttributedString(string: "Edit Account Information", attributes: underlineAttribute)
            button.setAttributedTitle(underlineAttributedString, for: UIControlState())
            button.addTarget(self, action: #selector(showAccountInfo), for: .touchUpInside)
        } else if section == 1 {
            let underlineAttributedString = NSAttributedString(string: "Edit Payment Information", attributes: underlineAttribute)
            button.setAttributedTitle(underlineAttributedString, for: UIControlState())
            button.addTarget(self, action: #selector(showPaymentInfo), for: .touchUpInside)
        }
        footerView.addSubview(button)
        return footerView
    }
}

extension AccountSettingsViewController: STPAddCardViewControllerDelegate {
    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        self.dismiss(animated: true, completion: nil)
    }

    func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreateToken token: STPToken, completion: @escaping STPErrorBlock) {

        guard let user = PFUser.current() as? User else { return }
        StripeService().postNewPayment(user, token: token) { (result, error) in
            print("\(result) \(error)")
            if let error = error {
                self.simpleAlert("Could not add card", defaultMessage: "There was an issue adding your credit card", error: error, completion: { 
                    // nothing
                })
            }
            else {
                user.fetchInBackground(block: { (object, error) in
                    self.tableView.reloadData()
                    self.dismiss(animated: true, completion: nil)
                })
            }
            completion(error)
        }
    }
}
