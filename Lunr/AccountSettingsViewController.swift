//
//  AccountSettingsViewController.swift
//  Lunr
//
//  Created by Randall Spence on 8/21/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

private let NumberOfSectionsInTableView = 3
private let SectionTitles = ["Account Information", "Payment Information", "Call History"]
private let AccountInfoSectionTitles = ["Email:", "Name:", "Password:"]
private let PaymentInfoSectionTitles = ["Default:"]


// MARK: Dummy Data

struct TestCall {
    var date: NSDate
    var nameOfCaller: String
    var cost: Double
    var card: String
}

struct TestUser {
    var email: String
    var name: String
    var pass: String
    var card: String
}

private let dummyCalls: [TestCall] = [TestCall(date: NSDate(), nameOfCaller: "John Snow", cost: 24.50, card: "VISA - 1234")]
private let dummyUser: TestUser = TestUser(email: "JSnow@uknownothing.com", name: "John Snow", pass: "ucantseethis", card: "VISA **** **** **** 1234")

class AccountSettingsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var callHistory: [TestCall] = dummyCalls
    var user: TestUser = dummyUser

    var dateFormatter: NSDateFormatter {
        let df = NSDateFormatter()
        df.dateFormat = "MM/dd"
        return df
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = false
        self.navigationController?.navigationBar.backgroundColor = .whiteColor()
        self.navigationController?.navigationBar.tintColor = .lunr_darkBlue()
        self.navigationController?.navigationBar.addShadow()
        // Do any additional setup after loading the view, typically from a nib.
        self.title = "Account Settings"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .Plain, target: self, action: #selector(dismiss))

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 140

        self.tableView.separatorStyle = .None

        UIApplication.sharedApplication().statusBarStyle = .LightContent
        

    }

    func dismiss() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    func showAccountInfo() {
        let controller = UIStoryboard(name: "Randall", bundle: nil).instantiateViewControllerWithIdentifier("EditAccountSettingsViewController") as! EditAccountSettingsViewController
        let navigationController = UINavigationController(rootViewController: controller)
        self.navigationController?.presentViewController(navigationController, animated: true, completion: nil)
    }

    func showPaymentInfo() {
        // Placeholder
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
                cell.textField.text = user.email
                cell.textField.secureTextEntry = false
                cell.textField.placeholder = "add your email"
            case 1:
                cell.textField.text = user.name
                cell.textField.secureTextEntry = false
                cell.textField.placeholder = "add your name"
            case 2:
                cell.textField.text = user.pass
                cell.textField.secureTextEntry = true
                cell.textField.placeholder = "enter your password"
            default:
                return UITableViewCell()
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("AccountInfoCell", forIndexPath: indexPath) as! AccountInfoCell
            cell.detailLabel.text = PaymentInfoSectionTitles[row]
            cell.textField.text = user.card
            return cell
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("CallHistoryCell", forIndexPath: indexPath) as! CallHistoryCell
            let call = self.callHistory[row]
            cell.dateLabel.text = dateFormatter.stringFromDate(call.date)
            cell.nameLabel.text = call.nameOfCaller
            cell.priceLabel.text = String(call.cost)
            cell.cardLabel.text = call.card
            cell.separatorView.backgroundColor = UIColor.lunr_separatorGray()
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0 : return AccountInfoSectionTitles.count
        case 1 : return PaymentInfoSectionTitles.count
        case 2 : return callHistory.count
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
