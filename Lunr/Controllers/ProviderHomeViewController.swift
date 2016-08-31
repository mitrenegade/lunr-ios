//
//  ProviderHomeViewController.swift
//  Lunr
//
//  Created by Brent Raines on 8/29/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class ProviderHomeViewController: UIViewController {
    
    // MARK: Properties
    @IBOutlet weak var onDutyToggleButton: LunrButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        onDutyToggleButton.cornerRadius = onDutyToggleButton.bounds.height / 2
        updateUI()
    }
    
    @IBAction func toggleOnDuty(sender: AnyObject) {
        if let user = PFUser.currentUser() {
            onDutyToggleButton.busy = true
            user.available = !user.available
            user.saveInBackgroundWithBlock { [weak self] (success, error) in
                self?.onDutyToggleButton.busy = false
                if success {
                    self?.updateUI()
                } else if let error = error {
                    self?.simpleAlert("There was an error", defaultMessage: nil, error: error)
                }
            }
        }
    }
    
    private func updateUI() {
        if let user = PFUser.currentUser() {
            let onDutyTitle = user.available ? "Go Offline" : "Go Online"
            onDutyToggleButton.setTitle(onDutyTitle, forState: .Normal)
        }
    }
}
