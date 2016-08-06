//
//  LoginViewController.swift
//  Lunr
//
//  Created by Bobby Ren on 8/6/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import ParseFacebookUtilsV4
import Parse

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
                user.saveInBackground()
            } else {
                print(error)
            }
        })
    }

    @IBAction func loginWithEmail(sender: UIButton) {
        print("Login with email")
    }
}
