import UIKit
import ParseFacebookUtilsV4
import Parse

class FacebookViewController: UIViewController {
    
    @IBAction func loginWithFacebook(sender: UIButton) {
        let readPermissions = ["public_profile", "email", "user_friends"]
        PFFacebookUtils.logInInBackgroundWithReadPermissions(readPermissions) {
            [weak self] (user: PFUser?, error: NSError?) -> Void in
            if let user = user {
                self?.updateUserProfile(user)
                self?.loginQBUser(user)
                if user.isNew {
                    print("User signed up and logged in through Facebook!")
                } else {
                    print("User logged in through Facebook!")
                }
                
            } else {
                print("Uh oh. The user cancelled the Facebook login.")
            }
        }
    }
    
    func updateUserProfile(user: PFUser) {
        let request = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "first_name, last_name, name, email"])
        request.startWithCompletionHandler({[weak self]  (connection, result, error) -> Void in
            if error == nil {
                if let firstName = result?["first_name"] as? String {
                    user["firstName"] = firstName
                }
                if let lastName = result?["last_name"] as? String {
                    user["lastName"] = lastName
                }
                user.email = result?["email"] as? String
                user.saveInBackgroundWithBlock({[ weak self ]  (success, error) in
                    if let error = error {
                        print("error")
                        if error.code == PFErrorCode.ErrorUsernameTaken.rawValue || error.code == PFErrorCode.ErrorUserEmailTaken.rawValue {
                            // For error "Account already exists for this email address." when logging in via facebook with an account that was created w/ email.
                            self?.simpleAlert("Error logging in", defaultMessage: "We had an issue logging you in", error: error, completion: nil)
                            PFUser.logOutInBackgroundWithBlock {(error) in
                                // should already be in login page
                            }
                        }
                    }
                    else {
                        self?.notify(.LoginSuccess)
                    }
                })
            } else {
                print(error)
                self?.simpleAlert("Error logging in", defaultMessage: "We had an issue logging you in", error: error, completion: {
                    PFUser.logOutInBackgroundWithBlock { [weak self] (error) in
                        self?.notify(.LogoutSuccess)
                    }
                })
            }
        })
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let nav = segue.destinationViewController as? UINavigationController else { return }
        guard let controller = nav.viewControllers[0] as? EmailViewController else { return }

        if segue.identifier == Segue.Login.GoToSignup.rawValue {
            controller.isSignup = true
        }
        else if segue.identifier == Segue.Login.GoToLogin.rawValue {
            controller.isSignup = false
        }
    }
    
    private func loginQBUser(user: PFUser) {
        guard let userID = user.objectId else { return }
        QBUserService.sharedInstance.loginQBUser(userID, completion: nil)
    }
}
