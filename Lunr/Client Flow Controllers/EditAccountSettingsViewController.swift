//
//  EditAccountSettingsViewController.swift
//  Lunr
//
//  Created by Randall Spence on 8/28/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class EditAccountSettingsViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var viewOverlay: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    weak var currentInput: UITextField?

    @IBOutlet var saveButtonToBottomConstraint: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Account Settings"
        self.view.backgroundColor = .whiteColor()
        self.navigationController?.navigationBar.backgroundColor = .whiteColor()
        self.navigationController?.navigationBar.tintColor = .lunr_darkBlue()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .Plain, target: self, action: #selector(dismiss))

        configureTextFields()
        
        self.toggleActivity(false)
    }

    func configureTextFields() {
        for view in self.view.subviews {
            guard view is UITextField else  {
                continue
            }
            if let textField = view as? UITextField {
                textField.layer.borderColor = UIColor.lunr_lightBlue().CGColor
                textField.layer.borderWidth = 2.0
                textField.layer.cornerRadius = 8.0
                let spacerView = UIView(frame:CGRect(x:0, y:0, width:10, height:10))
                textField.leftViewMode = .Always
                textField.leftView = spacerView
            }
        }
        self.refreshTextFields()
    }
    
    func refreshTextFields() {
        guard let user = PFUser.currentUser() as? User else { return }
        if let email = user.email {
            self.emailTextField.text = email
        }
        if let firstName = user.firstName {
            self.firstNameTextField.text = firstName
        }
        if let lastName = user.lastName {
            self.lastNameTextField.text = lastName
        }
    }

    func dismiss() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func toggleActivity(show: Bool = false) {
        if show {
            self.viewOverlay.hidden = false
            self.activityIndicator.startAnimating()
        }
        else {
            self.viewOverlay.hidden = true
            self.activityIndicator.stopAnimating()
        }
    }
}

extension EditAccountSettingsViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(textField: UITextField) {
        self.currentInput = textField
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        print("new value: \(textField.text)")
        guard let user = PFUser.currentUser() as? User else { return }
        
        if currentInput == self.emailTextField {
            guard let email = self.emailTextField.text where email.isValidEmail() else {
                self.emailTextField.text = nil
                return
            }
            user.email = self.emailTextField.text
            self.toggleActivity(true)
            user.saveInBackgroundWithBlock({ (success, error) in
                self.refreshTextFields()
                self.toggleActivity(false)
            })
        }
        else if currentInput == self.firstNameTextField {
            guard let name = self.firstNameTextField.text where !name.isEmpty else {
                self.firstNameTextField.text = nil
                return
            }
            user.firstName = self.firstNameTextField.text
            self.toggleActivity(true)
            user.saveInBackgroundWithBlock({ (success, error) in
                self.refreshTextFields()
                self.toggleActivity(false)
            })
        }
        else if currentInput == self.lastNameTextField {
            guard let name = self.lastNameTextField.text where !name.isEmpty else {
                self.lastNameTextField.text = nil
                return
            }
            user.lastName = self.lastNameTextField.text
            self.toggleActivity(true)
            user.saveInBackgroundWithBlock({ (success, error) in
                self.refreshTextFields()
                self.toggleActivity(false)
            })
        }
    }
}


