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

    func postReview(_ call: Call, rating: Double, feedback: String, completion: ((_ review: Review?, _ error: NSError?)->Void)?) {
        let review = Review(call: call, rating: rating, text: feedback)
        review.saveInBackground { (success, error) in
            if let error = error {
                completion?(nil, error as NSError?)
            }
            else {
                completion?(review, nil)
            }
        }
    }
}
