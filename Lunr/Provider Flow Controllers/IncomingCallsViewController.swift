//
//  IncomingCallsViewController.swift
//  Lunr
//
//  Created by Bobby Ren on 12/3/16.
//  Copyright © 2016 RenderApps. All rights reserved.
//

import UIKit
import Parse
import ParseLiveQuery

protocol IncomingCallsDelegate: class {
    func incomingCallsChanged()
    func clickedIncomingCall(conversation: Conversation)
}

class IncomingCallsViewController: UITableViewController {

    // live query for Parse objects
    let liveQueryClient = ParseLiveQuery.Client()
    var subscription: Subscription<Conversation>?
    var conversations: [Conversation]?
    
    weak var delegate: IncomingCallsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.refreshCalls()
        self.subscribeToUpdates()
        
        self.tableView.estimatedRowHeight = 68
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func shouldShow() -> Bool {
        guard let user = PFUser.current() as? User, user.available else {
            return false
        }
        
        if let conversations = self.conversations {
            return conversations.count > 0 // TODO: if there's one conversation, the prettier providerStatusView should show a "Reply" button
        }
        return false
    }
    
    func refreshCalls() {
        guard let user = PFUser.current(), let userId = user.objectId else {
            self.testAlert("Could not refresh incoming calls", message: "Invalid user or userId", type: .RefreshIncomingCallsFailed, error: nil, params: nil, completion: nil)
            return
        }
        guard let query: PFQuery<Conversation> = Conversation.query() as? PFQuery<Conversation> else { return }
        query.whereKey("providerId", equalTo: userId)
        query.whereKey("status", containedIn: [ConversationStatus.new.rawValue, ConversationStatus.current.rawValue])
        query.whereKey("expiration", greaterThan: NSDate().addingTimeInterval(-30))
        query.addDescendingOrder("expiration")
        query.findObjectsInBackground { (results, error) in
            if let error = error {
                self.testAlert("Could not refresh incoming calls", message: "Query failed to find objects", type: .RefreshIncomingCallsFailed, error: error, params: nil, completion: nil)
            }
            self.conversations = results
            self.tableView.reloadData()
            self.delegate?.incomingCallsChanged()
        }
    }


    func subscribeToUpdates() {
        if LOCAL_TEST {
            return
        }
        
        guard let user = PFUser.current(), let userId = user.objectId else { return }
        guard let query: PFQuery<Conversation> = Conversation.query() as? PFQuery<Conversation> else { return }
        query.whereKey("providerId", equalTo: userId)
        
        self.subscription = liveQueryClient.subscribe(query)
            .handle(Event.updated, { (_, object) in
                /*
                if let conversations = self.conversations {
                    var changed = false
                    for conversation in conversations {
                        if conversation.objectId == object.objectId, let index = conversations.index(of: conversation) {
                            self.conversations!.remove(at: index)
                            self.conversations!.insert(object, at: index)
                            changed = true
                        }
                    }
                    if changed {
                        DispatchQueue.main.async(execute: {
                            print("received update for provider: \(object.objectId!)")
                            self.tableView.reloadData()
                            self.delegate?.incomingCallsChanged()
                        })
                    }
                }
                */
                self.refreshCalls()
            })
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.conversations?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IncomingCallCell", for: indexPath) as? IncomingCallCell

        // Configure the cell...
        if let conversation = self.conversations?[indexPath.row] {
            cell?.configure(conversation: conversation)
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Incoming calls"
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        if let conversation = self.conversations?[indexPath.row] {
            self.delegate?.clickedIncomingCall(conversation: conversation)
        }
        else {
            self.testAlert("Could not select conversation", message: nil, type: .InvalidConversationSelected, error: nil, params: ["selectedRow": indexPath.row, "conversations": self.conversations?.count ?? 0], completion: nil)
        }
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
