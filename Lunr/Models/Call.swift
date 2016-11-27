//
//  CallService.swift
//  Lunr
//
//  Created by Bobby Ren on 8/30/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Parse
import Foundation

class Call: PFObject {
    // PFSubclassing and NSManaged is required so that PFObject.init() can be used, and PFObject's getters and setters correctly set key-value pairs that save to Parse
    @NSManaged var duration: NSNumber?
    @NSManaged var totalCost: NSNumber?
    @NSManaged var date: Date?
    @NSManaged var rate: NSNumber?
    
    @NSManaged var client: User?
    @NSManaged var provider: User?
    @NSManaged var review: Review?
    
    //var paymentMethod: Card

    // Call cannot be created in the iOS SDK because it requires a provider.
    // PFUser will throw an error because setting call.provider forces provider to be saved
    // and you can't alter a user other than the one that was logged in.
    // Call must be created via cloudcode
}

extension Call: PFSubclassing {
    static func parseClassName() -> String {
        return "Call"
    }
}

extension Call {
    var totalDurationString: String {
        let totalTime = duration as? Double ?? 0
        let minutes = floor(totalTime / 60.0)
        let seconds = floor(totalTime - minutes * 60)
        if minutes == 0 {
            return "\(seconds) seconds"
        }
        return "\(minutes)min \(seconds)sec"
    }
    
    var totalCostString: String {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = NumberFormatter.Style.currency
        // localize to your grouping and decimal separator
        currencyFormatter.locale = Locale.current
        
        if totalCost == nil || totalCost == 0 {
            // calculate totalCost for display only
            let rate = self.rate as? Double ?? 0
            let time = self.duration as? Double ?? 0
            self.totalCost = time / 60.0 * rate as NSNumber? // time is in seconds; rate is in minutes

        }
        
        return currencyFormatter.string(from: self.totalCost as? Double as NSNumber? ?? 0.0)!
    }
}
