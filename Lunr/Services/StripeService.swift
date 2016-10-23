//
//  StripeService.swift
//  Lunr
//
//  Created by Bobby Ren on 10/3/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import Stripe

class StripeService: NSObject {
    func postNewPayment(user: User, token: STPToken, completion: ((result: AnyObject?, error: NSError?)->Void)?) {
        
        var params = ["stripeToken": token.tokenId]
        if let last4 = token.card?.last4() {
            params["last4"] = last4
        }
        PFCloud.callFunctionInBackground("updatePayment", withParameters: params) { (result, error) in
            print("Results \(result) error \(error)")
            if let error = error {
                completion?(result: nil, error: error)
            }
            else {
                completion?(result: result, error: nil)
            }
        }
    }
    
    func paymentStringForUser(user: User?) -> String {
        guard let user = user else { return "None" }
        if let last4 = user.objectForKey("last4") as? String {
            return "Credit Card *\(last4)"
        }
        return "None"
    }
}
