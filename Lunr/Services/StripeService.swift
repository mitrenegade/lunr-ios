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
}
