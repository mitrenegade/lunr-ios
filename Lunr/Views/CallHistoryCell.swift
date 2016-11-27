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
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var cardLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var ratingView: StarRatingView!

    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MM/dd"
        return df
    }
    
    func configure(_ call: Call) {
        if let date = call.date {
            self.dateLabel.text = dateFormatter.string(from: date as Date)
        }
        
        if self.nameLabel.text == nil {
            self.nameLabel.text = "..."
        }
        if let user = PFUser.current() as? User, !user.isProvider, let provider = call.provider {
            provider.fetchIfNeededInBackground(block: { (result, error) in
                self.nameLabel.text = provider.displayString
            })
        }
        else if let user = PFUser.current() as? User, user.isProvider, let client = call.client {
            client.fetchIfNeededInBackground(block: { (result, error) in
                self.nameLabel.text = client.displayString
            })
        }
        self.priceLabel.text = String(call.totalCostString)
        self.cardLabel.text = StripeService().paymentStringForUser(PFUser.current() as? User)
        self.separatorView.backgroundColor = UIColor.lunr_separatorGray()

        if let pointer = call.review {
            print("pointer exists")
            self.ratingView.isHidden = true
            self.rateLabel.isHidden = true
            pointer.fetchInBackground(block: { (result, error) in
                if let review = result as? Review {
                    print("review exists")
                    self.ratingView.isHidden = false
                    self.ratingView.currentRating = Int(floor(review.rating ?? 0))
                }
            })
        }
        else {
            self.ratingView.isHidden = true
            self.rateLabel.isHidden = false
        }
    }
}


class ProviderCallHistoryCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var ratingView: StarRatingView!
    @IBOutlet weak var separatorView: UIView!
    
    var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy"
        return dateFormatter
    }
    
    func configure(_ call: Call) {
        if let date = call.date {
            self.dateLabel.text = dateFormatter.string(from: date as Date)
        }
        
        if let user = PFUser.current() as? User, user.isProvider, let client = call.client {
            client.fetchIfNeededInBackground(block: { (result, error) in
                self.nameLabel.text = "Call with \(client.displayString)"
            })
        }
        
        let totalTime = call.duration as? TimeInterval ?? 0
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

        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = NumberFormatter.Style.currency
        // localize to your grouping and decimal separator
        currencyFormatter.locale = Locale.current
        let totalEarnings = call.totalCost as? Double ?? 0
        let earningsString = currencyFormatter.string(from: NSNumber(value: totalEarnings))
        priceLabel.text = earningsString

        //self.separatorView.backgroundColor = UIColor.lunr_separatorGray()
        if let pointer = call.review {
            self.ratingView.isHidden = true
            pointer.fetchInBackground(block: { (result, error) in
                if let review = result as? Review {
                    self.ratingView.isHidden = false
                    self.ratingView.currentRating = Int(floor(review.rating ?? 0))
                }
            })
        }
        else {
            self.ratingView.isHidden = true
        }
    }
}

