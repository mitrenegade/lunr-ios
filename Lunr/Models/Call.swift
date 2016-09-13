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

