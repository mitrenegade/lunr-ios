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
    
    fileprivate var callsThisWeek: [Call]?
    fileprivate var callsLastWeek: [Call]?
    fileprivate var callsPast: [Call]?
    
    weak var weekSummaryController: WeekSummaryViewController?
    
    // MARK: Call History TableView
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Incoming calls
    @IBOutlet weak var incomingContainer: UIView!
    var incomingController: IncomingCallsViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onDutyToggleButton.backgroundColor = UIColor.lunr_darkBlue()
        
        providerStatusView.delegate = self
        
        updateUI()
        
        if let user = PFUser.current() as? User, user.isProvider && !user.available {
            let alert = UIAlertController(title: "Go Online?", message: "Do you want to become available to clients now?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Not yet", style: .destructive, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                self.toggleOnDuty(self.onDutyToggleButton)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
        self.refreshCallHistory()
        
        self.listenFor(.DialogFetched, action: #selector(handleIncomingChatRequest(_:)), object: nil)
        self.listenFor(NotificationType.Push.ReceivedInBackground.rawValue, action: #selector(handleBackgroundPush(_:)), object: nil)
        self.listenFor(.DialogCancelled, action: #selector(cancelChatRequest(_:)), object: nil)
        self.listenFor(.FeedbackUpdated, action: #selector(refreshCallHistory), object: nil)
        self.listenFor(.AppReturnedFromBackground, action: #selector(refreshAll), object: nil)
        
        incomingContainer.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.refreshAll()

        self.updateActive()
    }
    
    func updateActive() {
        if let user = PFUser.current() as? User {
            user.updateActive()
            print("updateActive")
        }
    }
    func refreshAll() {
        self.refreshCallHistory()
        self.incomingController?.refreshCalls()
    }
    
    deinit {
        self.stopListeningFor(NotificationType.Push.ReceivedInBackground.rawValue)
        self.stopListeningFor(.DialogFetched)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.shouldOpenDialogAutomatically = false
    }
    
    @IBAction func toggleOnDuty(_ sender: AnyObject) {
        if let user = PFUser.current() as? User, user.isProvider {
            onDutyToggleButton.busy = true
            user.available = !user.available
            user.saveInBackground { [weak self] (success, error) in
                self?.onDutyToggleButton.busy = false
                if success {
                    self?.updateUI()
                    if user.available {
                        PushService().enablePushNotifications({ (success) in
                            if !success {
                                self?.simpleAlert("There was an error enabling push", defaultMessage: nil, error: error as NSError?, completion: nil)
                            }
                        })
                        self?.incomingController?.refreshCalls()
                    }
                    else {
                        self?.incomingContainer.isHidden = true
                        PushService().unregisterParsePushSubscription()
                    }
                } else if let error = error {
                    self?.simpleAlert("There was an error", defaultMessage: nil, error: error as NSError?, completion: nil)
                }
            }
        }
        
        self.refreshCallHistory()
        self.updateActive()
    }
    
    fileprivate func updateUI() {
        // does not handle .NewRequest because updateUI is for online/offline and waiting
        if let user = PFUser.current() as? User {
            let onDutyTitle = user.available ? "Go Offline" : "Go Online"
            onDutyToggleButton.setTitle(onDutyTitle, for: UIControlState())
            providerStatusView.status = user.available ? .online : .offline
        }
        
        // clear locally stored dialog and userIds that were saved from previous notifications
        self.dialog = nil
        self.incomingPFUserId = nil
        self.updateActive()
    }
    
    func handleIncomingChatRequest(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let dialog = userInfo["dialog"] as? QBChatDialog, let incomingPFUserId = userInfo["pfUserId"] as? String else { return }
        guard QBNotificationService.sharedInstance.currentDialogID == nil else {
            print("Trying to open dialog \(dialog.id!) but dialog \(QBNotificationService.sharedInstance.currentDialogID!) already open")
            return
        }
        
        guard let user = PFUser.current() as? User, user.available else {
            return
        }
        
        QBUserService.getQBUUserForPFUserId(incomingPFUserId) { [weak self] (result) in
            if let user = result {
                self?.incomingPFUserId = incomingPFUserId
                self?.dialog = dialog
                //self?.providerStatusView.status = .newRequest(user)
                self?.incomingController?.refreshCalls()
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
    
    func cancelChatRequest(_ notification: Notification) {
        self.incomingPFUserId = nil
        self.dialog = nil
        self.updateUI()
        self.shouldOpenDialogAutomatically = false
    }
    
    func handleBackgroundPush(_ notification: Notification) {
        // this gets called when the app comes from background by clicking on a push
        self.shouldOpenDialogAutomatically = true
    }
    
    func didClickReply() {
        if let chatNavigationVC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ProviderChatNavigationController") as? UINavigationController, let chatVC = chatNavigationVC.viewControllers[0] as? ProviderChatViewController {
            guard let dialog = self.dialog, let userId = self.incomingPFUserId else {
                self.simpleAlert("Still loading dialog", message: "Please wait a few seconds and try again")
                return
            }
            chatVC.dialog = dialog
            chatVC.incomingPFUserId = userId
            QBNotificationService.sharedInstance.currentDialogID = dialog.id
            
            self.present(chatNavigationVC, animated: true, completion: {
                // reset to original state
                self.updateUI()
            })
        }
        
    }
    
    /* TODO:
     - dismiss a call request. (other than go offline)
     */
    
    func refreshCallHistory() {
        guard let user = PFUser.current() as? User, user.isProvider else { return }
        let endDate = Date()
        CallService.sharedInstance.queryCallsForUser(user, startDate:nil, endDate: endDate) { (results, error) in
            if let error = error {
                print("Error \(error)")
            }
            else {
                self.calls = results
                
                // this week
                let now = Date()
                var startDate = now.mondaysDate
                self.callsThisWeek = results?.filter({ (call) -> Bool in
                    return call.createdAt?.compare(startDate) == ComparisonResult.orderedDescending
                })
                self.weekSummaryController?.calls = self.callsThisWeek
                // last week
                var endDate = startDate
                startDate = startDate.addingTimeInterval(-7*24*3600)
                self.callsLastWeek = results?.filter({ (call) -> Bool in
                    return call.createdAt?.compare(startDate) == ComparisonResult.orderedDescending && call.createdAt?.compare(endDate) == ComparisonResult.orderedAscending
                })
                // this week
                endDate = startDate
                startDate = startDate.addingTimeInterval(-7*24*3600)
                self.callsPast = results?.filter({ (call) -> Bool in
                    return call.createdAt?.compare(startDate) == ComparisonResult.orderedDescending && call.createdAt?.compare(endDate) == ComparisonResult.orderedAscending
                })
                
                self.tableView.reloadData()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EmbedWeekSummary" {
            if let controller: WeekSummaryViewController = segue.destination as? WeekSummaryViewController {
                controller.calls = self.calls
                self.weekSummaryController = controller
            }
        }
        else if segue.identifier == "EmbedIncomingCalls" {
            if let controller: IncomingCallsViewController = segue.destination as? IncomingCallsViewController {
                controller.delegate = self
                self.incomingController = controller
            }
        }
    }
}

extension ProviderHomeViewController: UITableViewDataSource {
    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MM/dd"
        return df
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "CallHistoryCell", for: indexPath) as! ProviderCallHistoryCell
        guard let calls = self.calls, row < calls.count else {
            return cell
        }
        let call = calls[row]
        cell.configure(call)

        self.updateActive()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return callsThisWeek?.count ?? 0
        case 1:
            return callsLastWeek?.count ?? 0
        default:
            return callsPast?.count ?? 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        view.backgroundColor = UIColor.white
        let label: UILabel = UILabel(frame: CGRect(x: 16, y: 4, width: 200, height: 21))
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
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ProviderHomeViewController: IncomingCallsDelegate {
    func incomingCallsChanged() {
        self.incomingContainer.isHidden = !self.incomingController!.shouldShow()
    }
    
    func clickedIncomingCall(conversation: Conversation) {
        guard let incomingPFUserId = conversation.clientId, let dialogId = conversation.dialogId else {
            var params = [String:Any]()
            if let incomingPFUserId = conversation.clientId {
                params["incomingPFUserId"] = incomingPFUserId
            }
            if let dialogId = conversation.dialogId {
                params["dialogId"] = dialogId
            }
            self.testAlert("Incoming call could not be answered", message: nil, type: .ProviderClickedIncomingCallFailed, error: nil, params: params, completion: nil)
            return
        }

        QBNotificationService.sharedInstance.incomingPFUserId = incomingPFUserId
        
        // calling dispatch async for push notification handling to have priority in main queue
        DispatchQueue.main.async(execute: {
            SessionService.sharedInstance.chatService.fetchDialog(withID: dialogId) { [weak self] chatDialog in
                if let dialog = chatDialog {
                    self?.incomingPFUserId = incomingPFUserId
                    self?.dialog = chatDialog
                    self?.didClickReply()
                
                    conversation.status = ConversationStatus.current.rawValue
                    conversation.saveInBackground()
                }
                else {
                    SessionService.sharedInstance.chatService.loadDialog(withID: dialogId, completion: { (chatDialog) in
                        self?.incomingPFUserId = incomingPFUserId
                        self?.dialog = chatDialog
                        self?.didClickReply()
                        
                        conversation.status = ConversationStatus.current.rawValue
                        conversation.saveInBackground()
                    })
                }
            }
        });

    }
}

extension Date {
    struct Gregorian {
        static let calendar = Calendar(identifier: .gregorian)
    }
    var startOfWeek: Date {
        guard let date = Gregorian.calendar.date(from: Gregorian.calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else {
            return NSDate() as! Date
        }
        return date
    }
    
    var mondaysDate: Date {
        return Calendar(identifier: .iso8601).date(from: Calendar(identifier: .iso8601).dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
    }
    
}
