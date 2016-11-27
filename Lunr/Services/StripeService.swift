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
    func postNewPayment(_ user: User, token: STPToken, completion: ((_ result: AnyObject?, _ error: NSError?)->Void)?) {
        
        var params = ["stripeToken": token.tokenId]
        if let last4 = token.card?.last4() {
            params["last4"] = last4
        }
        PFCloud.callFunction(inBackground: "updatePayment", withParameters: params) { (result, error) in
            print("Results \(result) error \(error)")
            if let error = error {
                completion?(nil, error as NSError?)
            }
            else {
                completion?(result as AnyObject?, nil)
            }
        }
    }
    
    func paymentStringForUser(_ user: User?) -> String {
        guard let user = user else { return "None" }
        if let last4 = user.object(forKey: "last4") as? String {
            return "Credit Card *\(last4)"
        }
        return "None"
    }
}
