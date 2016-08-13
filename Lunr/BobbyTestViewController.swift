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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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

    func logout() {
        PFUser.logOutInBackgroundWithBlock { (error) in
            self.appDelegate().didLogout()
        }
    }
    
    func initiateCall() {
        self.performSegueWithIdentifier("GoToCallUser", sender: nil)
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GoToCallUser" {
            if let user: QBUUser = sender as? QBUUser {
                let controller: CallViewController = segue.destinationViewController as! CallViewController
                controller.targetUser = user
            }
        }
    }

}

