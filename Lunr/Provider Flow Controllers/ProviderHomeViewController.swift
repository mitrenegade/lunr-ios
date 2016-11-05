    //
//  ProviderHomeViewController.swift
//  Lunr
//
//  Created by Brent Raines on 8/29/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class ProviderHomeViewController: UIViewController, ProviderStatusViewDelegate {
    
    // MARK: Properties
    @IBOutlet weak var providerStatusView: ProviderStatusView!
    @IBOutlet weak var onDutyToggleButton: LunrRoundActivityButton!
    let chatSegue = "chatWithClient"

    var dialog: QBChatDialog?
    var incomingPFUserId: String?
    var shouldOpenDialogAutomatically = false
    
    var calls: [Call]?
    
    private var callsThisWeek: [Call]?
    private var callsLastWeek: [Call]?
    private var callsPast: [Call]?
    
    weak var weekSummaryController: WeekSummaryViewController?
    
    // MARK: Call History TableView
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onDutyToggleButton.backgroundColor = UIColor.lunr_darkBlue()
        
        providerStatusView.delegate = self
        
        updateUI()
        
        if let user = PFUser.currentUser() as? User where user.available {
            PushService().enablePushNotifications({ (success) in
                print("User is available and push is enabled")
            })
        }
        
        self.refreshCallHistory()
        
        self.listenFor(.DialogFetched, action: #selector(handleIncomingChatRequest(_:)), object: nil)
        self.listenFor(NotificationType.Push.ReceivedInBackground.rawValue, action: #selector(handleBackgroundPush(_:)), object: nil)
    }
    
    deinit {
        self.stopListeningFor(NotificationType.Push.ReceivedInBackground.rawValue)
        self.stopListeningFor(.DialogFetched)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.shouldOpenDialogAutomatically = false
    }
    
    @IBAction func toggleOnDuty(sender: AnyObject) {
        if let user = PFUser.currentUser() as? User {
            onDutyToggleButton.busy = true
            user.available = !user.available
            user.saveInBackgroundWithBlock { [weak self] (success, error) in
                self?.onDutyToggleButton.busy = false
                if success {
                    self?.updateUI()
                    if user.available {
                        PushService().enablePushNotifications({ (success) in
                            if !success {
                                self?.simpleAlert("There was an error enabling push", defaultMessage: nil, error: error, completion: nil)
                            }
                        })
                    }
                    else {
                        PushService().unregisterQBPushSubscription()
                    }
                } else if let error = error {
                    self?.simpleAlert("There was an error", defaultMessage: nil, error: error, completion: nil)
                }
            }
        }
    }
    
    private func updateUI() {
        // does not handle .NewRequest because updateUI is for online/offline and waiting
        if let user = PFUser.currentUser() as? User {
            let onDutyTitle = user.available ? "Go Offline" : "Go Online"
            onDutyToggleButton.setTitle(onDutyTitle, forState: .Normal)
            providerStatusView.status = user.available ? .Online : .Offline
        }
        
        // clear locally stored dialog and userIds that were saved from previous notifications
        self.dialog = nil
        self.incomingPFUserId = nil
    }
    
    func handleIncomingChatRequest(notification: NSNotification) {
        guard let userInfo = notification.userInfo, dialog = userInfo["dialog"] as? QBChatDialog, incomingPFUserId = userInfo["pfUserId"] as? String else { return }
        guard QBNotificationService.sharedInstance.currentDialogID == nil else {
            print("Trying to open dialog \(dialog.ID!) but dialog \(QBNotificationService.sharedInstance.currentDialogID!) already open")
            return
        }
        
        QBUserService.getQBUUserForPFUserId(incomingPFUserId) { [weak self] (result) in
            if let user = result {
                self?.incomingPFUserId = incomingPFUserId
                self?.dialog = dialog
                self?.providerStatusView.status = .NewRequest(user)
                if self?.shouldOpenDialogAutomatically ?? false {
                    self?.didClickReply()
                }
            }
            else {
                print("Could not load incoming user! Ignore it (?)")
            }
            self?.shouldOpenDialogAutomatically = false
        }
    }
    
    func handleBackgroundPush(notification: NSNotification) {
        // this gets called when the app comes from background by clicking on a push
        self.shouldOpenDialogAutomatically = true
    }
    
    func didClickReply() {
        if let chatNavigationVC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("ProviderChatNavigationController") as? UINavigationController, let chatVC = chatNavigationVC.viewControllers[0] as? ProviderChatViewController {
            guard let dialog = self.dialog, userId = self.incomingPFUserId else { return }
            chatVC.dialog = dialog
            chatVC.incomingPFUserId = userId
            QBNotificationService.sharedInstance.currentDialogID = dialog.ID
            
            self.presentViewController(chatNavigationVC, animated: true, completion: { 
                // reset to original state
                self.updateUI()
            })
        }

    }
    
    /* TODO:
     - dismiss a call request. (other than go offline)
    */
    
    func refreshCallHistory() {
        guard let user = PFUser.currentUser() as? User where user.isProvider else { return }
        //let startDate = NSDate().startOfWeek
        let endDate = NSDate()
        CallService.sharedInstance.queryCallsForUser(user, startDate:nil, endDate: endDate) { (results, error) in
            if let error = error {
                print("Error \(error)")
            }
            else {
                self.calls = results

                // this week
                var startDate = NSDate().startOfWeek
                self.callsThisWeek = results?.filter({ (call) -> Bool in
                    return call.createdAt?.compare(startDate) == NSComparisonResult.OrderedDescending
                })
                self.weekSummaryController?.calls = self.callsThisWeek
                // last week
                startDate = startDate.dateByAddingTimeInterval(-7*24*3600)
                self.callsLastWeek = results?.filter({ (call) -> Bool in
                    return call.createdAt?.compare(startDate) == NSComparisonResult.OrderedDescending
                })
                // this week
                startDate = startDate.dateByAddingTimeInterval(-7*24*3600)
                self.callsPast = results?.filter({ (call) -> Bool in
                    return call.createdAt?.compare(startDate) == NSComparisonResult.OrderedDescending
                })
                
                self.tableView.reloadData()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EmbedWeekSummary" {
            if let controller: WeekSummaryViewController = segue.destinationViewController as? WeekSummaryViewController {
                controller.calls = self.calls
                self.weekSummaryController = controller
            }
        }
    }
}

extension ProviderHomeViewController: UITableViewDataSource {
    var dateFormatter: NSDateFormatter {
        let df = NSDateFormatter()
        df.dateFormat = "MM/dd"
        return df
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCellWithIdentifier("CallHistoryCell", forIndexPath: indexPath) as! ProviderCallHistoryCell
        guard let calls = self.calls where row < calls.count else {
            return cell
        }
        let call = calls[row]
        cell.configure(call)
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return callsThisWeek?.count ?? 0
        case 1:
            return callsLastWeek?.count ?? 0
        default:
            return callsPast?.count ?? 0
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            if self.callsThisWeek?.count == 0 {
                return 0
            }
        case 1:
            if self.callsLastWeek?.count == 0 {
                return 0
            }
        default:
            if self.callsPast?.count == 0 {
                return 0
            }
        }
        return 30
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, 30))
        view.backgroundColor = UIColor.whiteColor()
        let label: UILabel = UILabel(frame: CGRectMake(16, 4, 200, 21))
        label.font = UIFont(name: "Futura-Medium", size: 16)
        switch section {
        case 0:
            label.text = "This week"
            if self.callsThisWeek?.count == 0 {
                return nil
            }
        case 1:
            label.text = "Last week"
            if self.callsLastWeek?.count == 0 {
                return nil
            }
        default:
            label.text = "Past calls"
            if self.callsPast?.count == 0 {
                return nil
            }
        }
        view.addSubview(label)
        return view
    }
}

extension ProviderHomeViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

extension NSDate {
    struct Calendar {
        static let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
    }
    var startOfWeek: NSDate {
        let sunday = Calendar.gregorian.dateFromComponents(Calendar.gregorian.components([.YearForWeekOfYear, .WeekOfYear ], fromDate: self))!
        return sunday.dateByAddingTimeInterval(3600*24)
    }
}