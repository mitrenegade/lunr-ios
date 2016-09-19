// This controller is a placeholder for the app flow as well as various button functionalities.
// logout
// initiateCall (generic)
// being used for chatViewController for now

import UIKit
import Parse

class ChatPlaceholderViewController: UIViewController {
    @IBOutlet weak var buttonLogout: UIButton!
    @IBOutlet weak var buttonCall: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var targetUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let user = self.targetUser {
            self.buttonCall.enabled = true
            self.buttonCall.setTitle("Call \(user.displayString)", forState: .Normal)
        }
        else {
            self.buttonCall.setTitle("No calls available", forState: .Normal)
        }
        self.activityIndicator.stopAnimating()
    }

    @IBAction func didClickButton(sender: UIButton) {
        if sender == self.buttonLogout {
            UserService.logout()
        }
        else if sender == self.buttonCall {
            self.initiateCall()
        }
    }
    
    func initiateCall() {
        self.performSegueWithIdentifier(Segue.Call.GoToCallUser.rawValue, sender: nil)
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Segue.Call.GoToCallUser.rawValue {
            if let user: PFUser = self.targetUser {
                let controller: CallViewController = segue.destinationViewController as! CallViewController
                controller.targetPFUser = user
            }
        }
    }

}

