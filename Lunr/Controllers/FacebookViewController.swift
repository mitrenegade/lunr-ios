import UIKit
import ParseFacebookUtilsV4
import Parse

class FacebookViewController: UIViewController {
    
    @IBAction func loginWithFacebook(sender: UIButton) {
      let readPermissions = ["public_profile", "email", "user_friends"]
      PFFacebookUtils.logInInBackgroundWithReadPermissions(readPermissions) {
        (user: PFUser?, error: NSError?) -> Void in
        if let user = user {
          self.updateUserProfile(user)
          if user.isNew {
            print("User signed up and logged in through Facebook!")
          } else {
            print("User logged in through Facebook!")
          }
          self.notify(.LoginSuccess)
        } else {
          print("Uh oh. The user cancelled the Facebook login.")
        }
      }
  }

    func updateUserProfile(user: PFUser) {
        let request = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "name, email"])
        request.startWithCompletionHandler({ (connection, result, error) -> Void in
            if error == nil {
                user["name"] = result?["name"] as? String
                user.email = result?["email"] as? String
                // TODO: This is throwing error, "Account already exists for this email address." when logging in via facebook with an account that was created w/ email.
                user.saveInBackground()
            } else {
                print(error)
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
}
