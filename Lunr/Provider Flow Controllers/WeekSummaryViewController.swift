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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy"
        let start = Date().mondaysDate
        labelDate.text = "Week of \(dateFormatter.string(from: start))"
        
        self.refresh()
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
        
        var totalTime: TimeInterval = 0
        var totalEarnings: Double = 0
        for call: Call in calls {
            let duration = call.duration as? Double ?? 0
            totalTime += duration
            
            let amount = call.totalCost as? Double ?? 0
            totalEarnings += amount
        }
        
        let attributedCalls = "\(calls.count) total calls".attributedString("\(calls.count)")
        labelCalls.attributedText = attributedCalls

        let h = floor(totalTime/3600)
        let m = floor((totalTime - h * 3600)/60)
        let s = floor(totalTime - h*3600 - m*60)
        var timeString = "\(Int(s))s"
        if m>0 || h>0 {
            timeString = "\(Int(m))m\(timeString)"
        }
        if h>0 {
            timeString = "\(Int(h))h\(timeString)"
        }
        let attributedTime = "\(timeString) time online".attributedString("\(timeString)")
        labelTime.attributedText = attributedTime
        
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = NumberFormatter.Style.currency
        // localize to your grouping and decimal separator
        currencyFormatter.locale = Locale.current
        let earningsString = currencyFormatter.string(from: NSNumber(value: totalEarnings))
        labelEarnings.text = earningsString
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

extension String {
    func attributedString(_ substring: String) -> NSAttributedString? {
        var attributes = Dictionary<String, AnyObject>()
        attributes[NSForegroundColorAttributeName] = UIColor.lunr_grayText()
        attributes[NSFontAttributeName] = UIFont(name: "Futura-Medium", size: 12)
        
        let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: self, attributes: attributes) as NSMutableAttributedString
        let range = (self as NSString).range(of: substring)
        
        var otherAttrs = Dictionary<String, AnyObject>()
        otherAttrs[NSForegroundColorAttributeName] = UIColor.lunr_darkGrayText()
        attributedString.addAttributes(otherAttrs, range: range)
        
        return attributedString
    }
}
