//
//  EmailViewController.swift
//  Lunr
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//
// Login credentials are email and password for the user
// Parse: username and email are both email, password is whatever the user enters
// QBUser: username and password are parse ID. User should not know about QBUser

import UIKit
import Parse
import Quickblox

class EmailViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var inputEmail: UITextField!
    @IBOutlet weak var inputPassword: UITextField!
    @IBOutlet weak var inputConfirmation: UITextField!
    @IBOutlet weak var buttonSignup: UIButton!
    
    var isSignup: Bool = false
    
    var count = 0;
    
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
        }
        
        if TEST {
            self.inputEmail.text = "bobbyren@gmail.com"
            self.inputPassword.text = "test"
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

        print("Login attempt \(self.count)")
        self.count=self.count+1

        PFUser.logInWithUsernameInBackground(email, password: password) { (user, error) in
            if (error != nil) {
                print("Error: \(error)")
                self.simpleAlert("Could not log in", defaultMessage: nil, error: error)
            }
            else if let user = user {
                print("results: \(user)")
                
                if let userId = user.objectId {
                    self.loginQBUser(userId)
                }
                else {
                    self.simpleAlert("Could not log in", defaultMessage: "Invalid user id", error: nil)
                }
            }
            else {
                self.simpleAlert("Could not log in", defaultMessage: "Invalid user", error: nil)
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
    func createQBUser(parseUserId: String) {
        let user = QBUUser()
        user.login = parseUserId
        user.password = parseUserId
        QBRequest.signUp(user, successBlock: { (response, user) in
            print("results: \(user)")
            self.loginQBUser(parseUserId)
        }) { (errorResponse) in
            print("Error: \(errorResponse)")
            self.simpleAlert("Could not sign up", defaultMessage: "There was a problem setting up your chat account.", error: nil)
        }
    }
    
    func loginQBUser(parseUserId: String) {
        QBRequest.logInWithUserLogin(parseUserId, password: parseUserId, successBlock: { (response, user) in
            print("results: \(user)")
            user?.password = parseUserId // must set it again to connect to QBChat
            QBChat.instance().connectWithUser(user!) { (error) in
                if error != nil {
                    print("error: \(error)")
                    self.simpleAlert("Could not log in", defaultMessage: "There was a problem connecting to chat.",  error: nil)
                }
                else {
                    self.notify("login:success", object: nil, userInfo: nil)
                }
            }
        }) { (errorResponse) in
            print("Error: \(errorResponse)")
            
            if errorResponse.status.rawValue == 401 {
                self.createQBUser(parseUserId)
            }
            else {
                self.simpleAlert("Could not log in", defaultMessage: "There was a problem logging into your chat account.",  error: nil)
            }
        }
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}
