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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func didClickLogout(sender: UIButton) {
        PFUser.logOutInBackgroundWithBlock { (error) in
            self.appDelegate().didLogout()
        }
    }
    
}

