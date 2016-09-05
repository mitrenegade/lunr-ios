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
        
        guard let user = PFUser.currentUser() as? User else { return }

        let call = Call(duration: 10*60, totalCost: 35.25, client: user, provider: provider)
        call.saveInBackgroundWithBlock { (success, error) in
            print("success \(success) call \(call)")
            if let error = error {
                completion?(call: nil, error: error)
            }
            else {
                completion?(call: call, error: nil)
            }
        }
    }
}