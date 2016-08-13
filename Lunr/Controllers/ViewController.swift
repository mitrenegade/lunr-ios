//
//  ViewController.swift
//  Lunr
//
//  Created by Bobby Ren on 8/5/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class ViewController: UIViewController {

    @IBAction func didClickLogout(sender: UIButton) {
        PFUser.logOutInBackgroundWithBlock { (error) in
            self.appDelegate().didLogout()
        }
    }
}