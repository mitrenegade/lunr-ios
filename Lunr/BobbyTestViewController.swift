//
//  BobbyTestViewController.swift
//  Lunr
//
//  Created by Bobby Ren on 8/5/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//
// This controller is a placeholder for the app flow as well as various button functionalities.
// logout
// initiateCall (generic)

import UIKit
import Parse

class BobbyTestViewController: UIViewController {
    @IBOutlet weak var buttonLogout: UIButton!
    @IBOutlet weak var buttonCall: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var targetUser: PFUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.loadUsers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func didClickButton(sender: UIButton) {
        if sender == self.buttonLogout {
            self.logout()
        }
        else if sender == self.buttonCall {
            self.initiateCall()
        }
    }
    
    func loadUsers() {
        self.activityIndicator.startAnimating()
        self.buttonCall.setTitle(nil, forState: .Normal)
        self.buttonCall.enabled = false
        let query = PFUser.query()
        query?.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            self.activityIndicator.stopAnimating()
            if let users = result as? [PFUser] {
                for user in users {
                    if user.isProvider() {
                        self.targetUser = user
                        self.buttonCall.enabled = true
                        self.buttonCall.setTitle("Call \(user.displayString)", forState: .Normal)
                    }
                }
                if self.targetUser == nil {
                    self.buttonCall.setTitle("No calls available", forState: .Normal)
                }
            }
        }
    }

    func logout() {
        PFUser.logOutInBackgroundWithBlock { (error) in
            self.appDelegate().didLogout()
        }
    }
    
    func initiateCall() {
        self.performSegueWithIdentifier("GoToCallUser", sender: self.targetUser)
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GoToCallUser" {
            if let user: PFUser = sender as? PFUser {
                let controller: CallViewController = segue.destinationViewController as! CallViewController
                controller.targetUser = user
            }
        }
    }

}

