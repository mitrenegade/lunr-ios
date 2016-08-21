//
//  Provider.swift
//  Lunr
//
//  Created by Randall Spence on 8/6/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Foundation

struct Review {
    let text : String
    let rating : Double
}

class Provider : NSObject {
    let name : String
    let rating : Double
    let reviews : [Review]
    let ratePerMin : Double
    var available : Bool = false
    let skills : [String]
    let info : String

    init(name: String, rating: Double, reviews: [Review], ratePerMin : Double, skills: [String], info: String) {
        self.name = name
        self.rating = rating
        self.reviews = reviews
        self.ratePerMin = ratePerMin
        self.skills = skills
        self.info = info
    }

}
