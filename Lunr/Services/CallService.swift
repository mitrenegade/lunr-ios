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

    func postNewCall(providerId: String, duration: NSTimeInterval, totalCost: Double, completion: ((call: Call?, error: NSError?)->Void)?) {
        Call.registerSubclass()

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
    
    func queryCallsForUser(user: User?, completion: ((results: [Call]?, error: NSError?)->Void)?) {
        guard let user = user else {
            completion?(results: nil, error: nil)
            return
        }
        
        Call.registerSubclass()

        let query: PFQuery = Call.query()! //(className: "Call")
        if user.isProvider {
            query.whereKey("provider", equalTo: user)
        }
        else {
            query.whereKey("client", equalTo: user)
        }
        query.orderByDescending("createdAt")
        query.findObjectsInBackgroundWithBlock { (results, error) in
            let calls = results as? [Call]
            completion?(results: calls, error: error)
        }
    }
}
