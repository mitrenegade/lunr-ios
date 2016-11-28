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

    func postNewCall(_ clientId: String, duration: TimeInterval, totalCost: Double, completion: ((_ call: Call?, _ error: NSError?)->Void)?) {

        var rate: Double = 0
        if let user = PFUser.current() as? User, user.isProvider {
            rate = user.ratePerMin
            // TODO: discount?
        }
        
        let params = ["date": Date(), "duration": duration, "totalCost": totalCost, "clientId": clientId, "rate": rate] as [String : Any]
        PFCloud.callFunction(inBackground: "postNewCall", withParameters: params) { (results, error) in
            print("Results \(results) error \(error)")
            if let error = error {
                completion?(nil, error as NSError?)
            }
            else if let call = results as? Call {
                completion?(call, nil)
            }
        }
    }
    
    func queryCallsForUser(_ user: User?, startDate: Date? = nil, endDate: Date? = nil, completion: @escaping ((_ results: [Call]?, _ error: NSError?)->Void)) {
        /*
        guard let user = user else {
            completion(results: nil, error: nil)
            return
        }
        */

        let query: PFQuery = Call.query()! //(className: "Call")
        /*
        if user.isProvider {
            query.whereKey("provider", equalTo: user)
        }
        else {
            query.whereKey("client", equalTo: user)
        }
 */
        query.order(byDescending: "createdAt")
        if let start = startDate {
            query.whereKey("createdAt", greaterThanOrEqualTo: start)
        }
        if let end = endDate {
            query.whereKey("createdAt", lessThanOrEqualTo: end)
        }
        query.findObjectsInBackground { (results, error) in
            let calls = results as? [Call]
            completion(calls, error as NSError?)
        }
    }
    
    func queryCallWithId(_ callId: String?, completion: @escaping ((_ result: Call?, _ error: NSError?)->Void)) {
        guard let callId = callId else {
            completion(nil, nil)
            return
        }
 
        
        let query: PFQuery = Call.query()! //(className: "Call")
        query.getObjectInBackground(withId: callId) { (result, error) in
            let call = result as? Call
            completion(call, error as NSError?)
        }
    }
    
    func updateCall(_ call: Call, shouldSave: Bool = true, completion: @escaping ((_ result: Call?, _ error: NSError?)->Void)) {
        guard let start = call.date else { completion(call, nil); return }
        let duration = Date().timeIntervalSince(start as Date)
        call.duration = duration as NSNumber?
        // save the duration based on provider
        if shouldSave {
            let params: [AnyHashable: Any] = ["callId": call.objectId!, "duration": duration]
            PFCloud.callFunction(inBackground: "completeCall", withParameters: params, block: { (result, error) in
                completion(call, error as? NSError)
            })
        }
        else {
            // only client
            completion(call, nil)
        }
    }

}
