//
//  ProviderSettingsViewController.swift
//  Lunr
//
//  Created by Brent Raines on 10/14/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class ProviderSettingsViewController: UIViewController {
    @IBOutlet weak var logoutButton: LunrActivityButton!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var passwordLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        logoutButton.cornerRadius = logoutButton.bounds.height / 2
        logoutButton.backgroundColor = UIColor.lunr_darkBlue()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let currentUser = PFUser.current() as? User
        emailLabel.text = currentUser?.email
        nameLabel.text = currentUser?.displayString
    }

    @IBAction func editAccountInfo(_ sender: AnyObject) {
    }
    
    @IBAction func didClickLogout(_ sender: AnyObject) {
        let currentUser = PFUser.current() as? User
        currentUser?.setValue(false, forKey: "available")
        currentUser?.saveInBackground(block: { (success, error) in
            PushService().unregisterParsePushSubscription()
            UserService.logout()
        })
    }
}
