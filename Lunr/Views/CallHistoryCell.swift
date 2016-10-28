//
//  CallHistoryCell.swift
//  Lunr
//
//  Created by Randall Spence on 8/27/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Foundation
import Parse

class ClientCallHistoryCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var cardLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!

    var dateFormatter: NSDateFormatter {
        let df = NSDateFormatter()
        df.dateFormat = "MM/dd"
        return df
    }
    
    func configure(call: Call) {
        if let date = call.date {
            self.dateLabel.text = dateFormatter.stringFromDate(date)
        }
        
        if self.nameLabel.text == nil {
            self.nameLabel.text = "..."
        }
        if let user = PFUser.currentUser() as? User where !user.isProvider, let provider = call.provider {
            provider.fetchIfNeededInBackgroundWithBlock({ (result, error) in
                self.nameLabel.text = provider.displayString
            })
        }
        else if let user = PFUser.currentUser() as? User where user.isProvider, let client = call.client {
            client.fetchIfNeededInBackgroundWithBlock({ (result, error) in
                self.nameLabel.text = client.displayString
            })
        }
        self.priceLabel.text = String(call.totalCostString)
        self.cardLabel.text = StripeService().paymentStringForUser(PFUser.currentUser() as? User)
        self.separatorView.backgroundColor = UIColor.lunr_separatorGray()
    }
}


class ProviderCallHistoryCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var ratingView: StarRatingView!
    @IBOutlet weak var separatorView: UIView!
    
    var dateFormatter: NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy"
        return dateFormatter
    }
    
    func configure(call: Call) {
        if let date = call.date {
            self.dateLabel.text = dateFormatter.stringFromDate(date)
        }
        
        if let user = PFUser.currentUser() as? User where user.isProvider, let client = call.client {
            client.fetchIfNeededInBackgroundWithBlock({ (result, error) in
                self.nameLabel.text = "Call with \(client.displayString)"
            })
        }
        
        let totalTime = call.duration as? NSTimeInterval ?? 0
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
        let attributedTime = "Duration: \(timeString)".attributedString("\(timeString)")
        timeLabel.attributedText = attributedTime

        let currencyFormatter = NSNumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        // localize to your grouping and decimal separator
        currencyFormatter.locale = NSLocale.currentLocale()
        let totalEarnings = call.totalCost as? Double ?? 0
        let earningsString = currencyFormatter.stringFromNumber(totalEarnings)
        priceLabel.text = earningsString

        //self.separatorView.backgroundColor = UIColor.lunr_separatorGray()
    }
}
