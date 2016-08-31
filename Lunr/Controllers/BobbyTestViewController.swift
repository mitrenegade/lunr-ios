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

    @IBAction func didClickButton(sender: UIButton) {
        if sender == self.buttonLogout {
            self.logout()
        }
        else if sender == self.buttonCall {
            self.initiateCall()
        }
    }
    
    func loadUsers() {
        // TODO: this method will be used to populate a tableview of providers
        self.activityIndicator.startAnimating()
        self.buttonCall.setTitle(nil, forState: .Normal)
        self.buttonCall.enabled = false
        let query = PFUser.query()
        query?.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            self.activityIndicator.stopAnimating()
            if let users = result as? [PFUser] {
                for user in users {
                    if user.type == .Provider {
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
        PFUser.logOutInBackgroundWithBlock { [weak self] (error) in
            self?.notify(.LogoutSuccess)
        }
    }
    
    func initiateCall() {
        self.performSegueWithIdentifier(Segue.Call.GoToCallUser.rawValue, sender: self.targetUser)
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Segue.Call.GoToCallUser.rawValue {
            if let user: PFUser = sender as? PFUser {
                let controller: CallViewController = segue.destinationViewController as! CallViewController
                controller.targetPFUser = user
            }
        }
    }

}

