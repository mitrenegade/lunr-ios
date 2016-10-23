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
    @NSManaged var date: NSDate?
    @NSManaged var rate: NSNumber?
    
    @NSManaged var client: User?
    @NSManaged var provider: User?
    
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
        let currencyFormatter = NSNumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        // localize to your grouping and decimal separator
        currencyFormatter.locale = NSLocale.currentLocale()
        
        guard let cost = totalCost else { return currencyFormatter.stringFromNumber(0)! }
        return currencyFormatter.stringFromNumber(cost)!
    }
}
