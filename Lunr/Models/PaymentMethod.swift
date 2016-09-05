//
//  Card.swift
//  Lunr
//
//  Created by Bobby Ren on 9/2/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class PaymentMethod: PFObject {
    // Placeholder for Card that needs to be associated with payments and calls
    @NSManaged var type: String
    @NSManaged var last4: String
    
    override init () {
        super.init()
    }

}

extension PaymentMethod: PFSubclassing {
    static func parseClassName() -> String {
        return "PaymentMethod"
    }
}

