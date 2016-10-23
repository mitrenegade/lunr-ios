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
    
    var currentCallId: String? = nil // pfObjectId for a Call
    var currentCall: Call? = nil

    func postNewCall(clientId: String, duration: NSTimeInterval, totalCost: Double, completion: ((call: Call?, error: NSError?)->Void)?) {
        Call.registerSubclass()

        var rate: Double = 0
        if let user = PFUser.currentUser() as? User where user.isProvider {
            rate = user.ratePerMin
            // TODO: discount?
        }
        
        let params = ["date": NSDate(), "duration": duration, "totalCost": totalCost, "clientId": clientId, "rate": rate]
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
    
    func queryCallsForUser(user: User?, completion: ((results: [Call]?, error: NSError?)->Void)) {
        guard let user = user else {
            completion(results: nil, error: nil)
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
            completion(results: calls, error: error)
        }
    }
    
    func queryCallWithId(callId: String?, completion: ((result: Call?, error: NSError?)->Void)) {
        guard let callId = callId else {
            completion(result: nil, error: nil)
            return
        }
 
        Call.registerSubclass()
        
        let query: PFQuery = Call.query()! //(className: "Call")
        query.getObjectInBackgroundWithId(callId) { (result, error) in
            let call = result as? Call
            completion(result: call, error: error)
        }
    }
    
    func updateCall(call: Call, shouldSave: Bool = true, completion: ((result: Call?, error: NSError?)->Void)) {
        guard let start = call.date else { completion(result: call, error: nil); return }
        guard let rate = call.rate as? Double else { completion(result: call, error: nil); return }
        
        let duration = NSDate().timeIntervalSinceDate(start)
        let minutes = duration / 60
        
        call.duration = duration
        call.totalCost = minutes * rate
        // save the call
        if shouldSave {
            call.saveInBackgroundWithBlock({ (success, error) in
                completion(result: call, error: error)
            })
        }
        else {
            // only client
            completion(result: call, error: nil)
        }
    }

}
