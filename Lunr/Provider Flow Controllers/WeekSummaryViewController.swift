//
//  WeekSummaryViewController.swift
//  Lunr
//
//  Created by Bobby Ren on 10/27/16.
//  Copyright © 2016 RenderApps. All rights reserved.
//

import UIKit

class WeekSummaryViewController: UIViewController {

    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelCalls: UILabel!
    @IBOutlet weak var labelTime: UILabel!
    @IBOutlet weak var labelEarnings: UILabel!    
    
    var calls: [Call]? {
        didSet {
            self.refresh()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refresh() {
        guard let calls = self.calls else {
            return
        }
        print("calls: \(self.calls?.count)")
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy"
        let start = NSDate().startOfWeek
        labelDate.text = "Week of \(dateFormatter.stringFromDate(start))"
        
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
