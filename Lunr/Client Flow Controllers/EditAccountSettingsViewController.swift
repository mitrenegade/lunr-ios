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
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.backgroundColor = .white
        self.navigationController?.navigationBar.tintColor = .lunr_darkBlue()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(EditAccountSettingsViewController.dismissAccouintSettings))

        configureTextFields()
        
        self.toggleActivity(false)
    }

    func configureTextFields() {
        for view in self.view.subviews {
            guard view is UITextField else  {
                continue
            }
            if let textField = view as? UITextField {
                textField.layer.borderColor = UIColor.lunr_lightBlue().cgColor
                textField.layer.borderWidth = 2.0
                textField.layer.cornerRadius = 8.0
                let spacerView = UIView(frame:CGRect(x:0, y:0, width:10, height:10))
                textField.leftViewMode = .always
                textField.leftView = spacerView
            }
        }
        self.refreshTextFields()
    }
    
    func refreshTextFields() {
        guard let user = PFUser.current() as? User else { return }
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

    func dismissAccouintSettings() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func toggleActivity(_ show: Bool = false) {
        if show {
            self.viewOverlay.isHidden = false
            self.activityIndicator.startAnimating()
        }
        else {
            self.viewOverlay.isHidden = true
            self.activityIndicator.stopAnimating()
        }
    }
}

extension EditAccountSettingsViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.currentInput = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("new value: \(textField.text)")
        guard let user = PFUser.current() as? User else { return }
        
        if currentInput == self.emailTextField {
            guard let email = self.emailTextField.text, email.isValidEmail() else {
                self.emailTextField.text = nil
                return
            }
            user.email = self.emailTextField.text
            self.toggleActivity(true)
            user.saveInBackground(block: { (success, error) in
                self.refreshTextFields()
                self.toggleActivity(false)
            })
        }
        else if currentInput == self.firstNameTextField {
            guard let name = self.firstNameTextField.text, !name.isEmpty else {
                self.firstNameTextField.text = nil
                return
            }
            user.firstName = self.firstNameTextField.text
            self.toggleActivity(true)
            user.saveInBackground(block: { (success, error) in
                self.refreshTextFields()
                self.toggleActivity(false)
            })
        }
        else if currentInput == self.lastNameTextField {
            guard let name = self.lastNameTextField.text, !name.isEmpty else {
                self.lastNameTextField.text = nil
                return
            }
            user.lastName = self.lastNameTextField.text
            self.toggleActivity(true)
            user.saveInBackground(block: { (success, error) in
                self.refreshTextFields()
                self.toggleActivity(false)
            })
        }
    }
}


