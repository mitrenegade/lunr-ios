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
    let text : String
    let rating : Double
    
    init(rating: Double, text: String) {
        super.init()
        self.rating = rating
        self.text = text
    }
}

extension Review: PFSubclassing {
    static func parseClassName() -> String {
        return "Review"
    }
}

