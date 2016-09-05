//
//  Review.swift
//  Lunr
//
//  Created by Bobby Ren on 9/2/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class Review: PFObject {
    @NSManaged var text : String
    @NSManaged var rating : Double
    
    @NSManaged var provider: User?
    @NSManaged var client: User?
    @NSManaged var call: Call
    
    override init () {
        super.init()
    }

    init(call: Call, rating: Double, text: String) {
        super.init()
        self.rating = rating
        self.text = text
        
        self.call = call
        self.provider = call.provider
        self.client = call.client
    }
}

extension Review: PFSubclassing {
    static func parseClassName() -> String {
        return "Review"
    }
}

