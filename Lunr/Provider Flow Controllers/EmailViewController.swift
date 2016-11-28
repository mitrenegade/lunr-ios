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
    @IBOutlet weak var buttonSignup: LunrActivityButton!
    
    var isSignup: Bool = false
    
    var count = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button: UIButton = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 80, height: 30)
        button.setTitle("Cancel", for: UIControlState())
        button.setTitleColor(UIColor.black, for: UIControlState())
        button.addTarget(self, action: #selector(didClickCancel), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
        
        if !isSignup {
            self.buttonSignup.setTitle("Log in with email", for: UIControlState())
            self.inputConfirmation.isHidden = true
        }
        
        if TEST {
            self.inputEmail.text = "bobbyren@gmail.com"
            self.inputPassword.text = "test"
        }
    }
    
    func didClickCancel() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didClickButton(_ button: UIButton) {
        if isSignup {
            self.createEmailUser()
        }
        else {
            self.loginUser()
        }
    }
    
    func createEmailUser() {
        let email = self.inputEmail.text!.lowercased()
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
        
        self.buttonSignup.busy = true
        let user: PFUser = PFUser()
        user.username = email
        user.email = email
        user.password = password
        user.signUpInBackground {[weak self]  (success, error) in
            if let error = error as? NSError {
                print("Error: \(error)")
                self?.simpleAlert("Could not sign up", defaultMessage: nil, error: error, completion: nil)
                self?.buttonSignup.busy = false
            }
            else {
                print("results: \(user)")
                self?.loginUser()
            }
        }
    }
        
    func loginUser() {
        let email = self.inputEmail.text!.lowercased()
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

        self.buttonSignup.busy = true
        PFUser.logInWithUsername(inBackground: email, password: password) {[weak self]  (user, error) in
            guard error == nil else {
                print("Error: \(error)")
                self?.simpleAlert("Could not log in", defaultMessage: nil, error: error as NSError?, completion: nil)
                self?.buttonSignup.busy = false
                return
            }
            guard let user = user, let userId = user.objectId else {
                self?.simpleAlert("Could not log in", defaultMessage: "Invalid user id", error: nil, completion: nil)
                self?.buttonSignup.busy = false
                return
            }
            print("PFUser loaded: \(user)")
            
            QBUserService.sharedInstance.loginQBUser(userId, completion: { [weak self] (success, error) in
                if success {
                    self?.buttonSignup.busy = false
                    self?.notify(.LoginSuccess)
                }
                else {
                    self?.buttonSignup.busy = false
                    self?.simpleAlert("Could not log in", defaultMessage: "There was a problem connecting to chat.",  error: error, completion: nil)
                }
            })
        }
    }
    
    // MARK: - Utils
    fileprivate func isValidEmail(_ testStr:String) -> Bool {
        // http://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
        let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}
