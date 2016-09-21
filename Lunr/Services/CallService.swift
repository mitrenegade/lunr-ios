//
//  CallService.swift
//  Lunr
//
//  Created by Bobby Ren on 9/3/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Foundation
import Parse

class CallService: NSObject {
    static let sharedInstance: CallService = CallService()

    func postNewCall(provider: User, duration: NSTimeInterval, totalCost: Double, completion: ((call: Call?, error: NSError?)->Void)?) {
        Call.registerSubclass()

        guard let providerId = provider.objectId else { return }
        let params = ["date": NSDate(), "duration": duration, "totalCost": totalCost, "providerId": providerId]
        PFCloud.callFunctionInBackground("postNewCall", withParameters: params) { (results, error) in
            print("Results \(results) error \(error)")
            if let error = error {
                completion?(call: nil, error: error)
            }
            else if let call = results as? Call {
                completion?(call: call, error: nil)
            }
        }
    }
}
