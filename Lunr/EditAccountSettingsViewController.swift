//
//  EditAccountSettingsViewController.swift
//  Lunr
//
//  Created by Randall Spence on 8/28/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class EditAccountSettingsViewController: UIViewController {
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var currentPasswordLabel: UILabel!
    @IBOutlet var currentPasswordTextField: UITextField!
    @IBOutlet var newPasswordLabel: UILabel!
    @IBOutlet var newPasswordTextField: UITextField!
    @IBOutlet var saveButton: UIButton!

    @IBOutlet var saveButtonToBottomConstraint: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Account Settings"
        self.view.backgroundColor = .whiteColor()
        self.navigationController?.navigationBar.backgroundColor = .whiteColor()
        self.navigationController?.navigationBar.tintColor = .lunr_darkBlue()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .Plain, target: self, action: #selector(dismiss))

        configureTextFields()
        saveButton.backgroundColor = .lunr_darkBlue()
        registerForKeyboardNotifications()
    }

    func registerForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWasShown), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillBeHidden), name: UIKeyboardWillHideNotification, object: nil)
    }

    func keyboardWasShown(aNotification: NSNotification) {
        let info = aNotification.userInfo
        if let size = info?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue() {
            saveButtonToBottomConstraint.constant = size.height
        }
    }

    func keyboardWillBeHidden(aNotification: NSNotification) {
        saveButtonToBottomConstraint.constant = 0
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
    }

    @IBAction func saveButtonTapped(sender: UIButton) {
        // Placeholder
    }

    func dismiss() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension EditAccountSettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


