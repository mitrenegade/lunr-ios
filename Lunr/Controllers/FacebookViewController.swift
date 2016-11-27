import UIKit
import ParseFacebookUtilsV4
import Parse

class FacebookViewController: UIViewController {
    @IBOutlet var buttonFacebook: LunrActivityButton!
    
    @IBAction func loginWithFacebook(_ sender: UIButton) {
        buttonFacebook.busy = true
        let readPermissions = ["public_profile", "email", "user_friends"]
        PFFacebookUtils.logInInBackground(withReadPermissions: readPermissions) {
            [weak self] (user: PFUser?, error: Error?) -> Void in
            if let user = user {
                self?.updateUserProfile(user)
                if user.isNew {
                    print("User signed up and logged in through Facebook!")
                } else {
                    print("User logged in through Facebook!")
                }
                
            } else {
                print("Uh oh. The user cancelled the Facebook login.")
                self?.buttonFacebook.busy = false
                self?.simpleAlert("Error logging in", defaultMessage: "We had an issue logging you in", error: error as? NSError, completion: nil)
            }
        }
    }
    
    func updateUserProfile(_ user: PFUser) {
        let request = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "first_name, last_name, name, email"])
        request?.start(completionHandler: {[weak self]  (_, result, error) -> Void in
            if let result = result as? [String: String] {
                if let firstName = result["first_name"] {
                    user["firstName"] = firstName
                }
                if let lastName = result["last_name"] {
                    user["lastName"] = lastName
                }
                user.email = result["email"]
                user.saveInBackground(block: {[ weak self ]  (success, error) in
                    if let error = error as? NSError {
                        print("error")
                        self?.buttonFacebook.busy = false
                        if error.code == PFErrorCode.errorUsernameTaken.rawValue || error.code == PFErrorCode.errorUserEmailTaken.rawValue {
                            // For error "Account already exists for this email address." when logging in via facebook with an account that was created w/ email.
                            self?.simpleAlert("Error logging in", defaultMessage: "We had an issue logging you in", error: error, completion: nil)
                            PFUser.logOutInBackground {(error) in
                                // should already be in login page
                            }
                        }
                    }
                    else {
                        let userId = user.objectId!
                        QBUserService.sharedInstance.loginQBUser(userId, completion: { [weak self] (success, error) in
                            if success {
                                self?.buttonFacebook.busy = false
                                self?.notify(.LoginSuccess)
                            }
                            else {
                                self?.buttonFacebook.busy = false
                                self?.simpleAlert("Could not log in", defaultMessage: "There was a problem connecting to chat.",  error: error, completion: nil)
                            }
                        })
                    }
                })
            } else {
                print(error)
                self?.buttonFacebook.busy = false
                self?.simpleAlert("Error logging in", defaultMessage: "We had an issue logging you in", error: error as NSError?, completion: {
                    PFUser.logOutInBackground { [weak self] (error) in
                        self?.notify(.LogoutSuccess)
                    }
                })
            }
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nav = segue.destination as? UINavigationController else { return }
        guard let controller = nav.viewControllers[0] as? EmailViewController else { return }

        if segue.identifier == Segue.Login.GoToSignup.rawValue {
            controller.isSignup = true
        }
        else if segue.identifier == Segue.Login.GoToLogin.rawValue {
            controller.isSignup = false
        }
    }
    
}
