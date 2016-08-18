//
//  EmailViewController.swift
//  Lunr
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import Quickblox

class EmailViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var inputEmail: UITextField!
    @IBOutlet weak var inputPassword: UITextField!
    @IBOutlet weak var inputConfirmation: UITextField!
    @IBOutlet weak var buttonSignup: UIButton!
    
    var isSignup: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button: UIButton = UIButton(type: .Custom)
        button.frame = CGRectMake(0, 0, 80, 30)
        button.setTitle("Cancel", forState: .Normal)
        button.setTitleColor(UIColor.blackColor(), forState: .Normal)
        button.addTarget(self, action: #selector(didClickCancel), forControlEvents: .TouchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
        
        if !isSignup {
            self.buttonSignup.setTitle("Login with Email", forState: .Normal)
            self.inputConfirmation.hidden = true
            self.buttonSignup.addTarget(self, action: #selector(loginUser), forControlEvents: .TouchUpInside)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didClickCancel() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func didClickButton(button: UIButton) {
        if isSignup {
            self.createEmailUser()
        }
        else {
            self.loginUser()
        }
    }
    
    func createEmailUser() {
        let email = self.inputEmail.text!
        let password = self.inputPassword.text!
        let confirmation = self.inputConfirmation.text!
        
        if !self.isValidEmail(email) {
            print("Invalid email")
            return
        }
        
        if password.characters.count == 0 {
            print("Invalid password")
            return
        }
        
        if confirmation != password {
            print("Password and confirmation do not match")
            return
        }
        
        let user: PFUser = PFUser()
        user.username = email
        user.email = email
        user.password = password
        user.signUpInBackgroundWithBlock { (success, error) in
            if (error != nil) {
                print("Error: \(error)")
                self.simpleAlert("Could not sign up", defaultMessage: nil, error: error)
            }
            else {
                print("results: \(user)")
                self.notify("login:success", object: nil, userInfo: nil)
            }
        }
    }
        
    func loginUser() {
        let email = self.inputEmail.text!
        let password = self.inputPassword.text!
        
        if !self.isValidEmail(email) {
            print("Invalid email")
            return
        }
        
        if password.characters.count == 0 {
            print("Invalid password")
            return
        }

        PFUser.logInWithUsernameInBackground(email, password: password) { (user, error) in
            if (error != nil) {
                print("Error: \(error)")
                self.simpleAlert("Could not log in", defaultMessage: nil, error: error)
            }
            else {
                print("results: \(user)")
                self.notify("login:success", object: nil, userInfo: nil)
            }
        }
    }
    
    // MARK: - Utils
    private func isValidEmail(testStr:String) -> Bool {
        // http://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
        let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }

    // MARK: QuickBlox
    func createQBUser(email: String, password: String) {
        let user = QBUUser()
        user.password = password
        user.email = email
        QBRequest.signUp(user, successBlock: { (response, user) in
            print("results: \(user)")
            self.loginUser()
        }) { (errorResponse) in
            print("Error: \(errorResponse)")
            self.simpleAlert("Could not sign up", defaultMessage: nil, error: nil)
        }
    }
    
    func loginQBUser(email: String, password: String) {
        QBRequest.logInWithUserEmail(email, password: password, successBlock: { (response, user) in
            print("results: \(user)")
            QBChat.instance().connectWithUser(user!) { (error) in
                if error != nil {
                    print("error: \(error)")
                }
                else {
                    self.notify("login:success", object: nil, userInfo: nil)
                }
            }
        }) { (errorResponse) in
            print("Error: \(errorResponse)")
            self.simpleAlert("Could not log in", defaultMessage: nil,  error: nil)
        }
    }

}
