//
//  ReviewService.swift
//  Lunr
//
//  Created by Bobby Ren on 9/5/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Foundation
import Parse

class ReviewService: NSObject {
    static let sharedInstance: ReviewService = ReviewService()

    func postReview(call: Call, rating: Double, feedback: String, completion: ((review: Review?, error: NSError?)->Void)?) {
        let review = Review(call: call, rating: rating, text: feedback)
        review.saveInBackgroundWithBlock { (success, error) in
            if let error = error {
                completion?(review: nil, error: error)
            }
            else {
                call.review = review
                call.saveInBackground()
                completion?(review: review, error: nil)
            }
        }
    }
}
