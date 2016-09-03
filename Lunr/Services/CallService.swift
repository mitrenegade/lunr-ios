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
    
    func createTestCallInParse() {
        Call.registerSubclass()
        
        guard let user = PFUser.currentUser() as? User else { return }
        
        let client: User? = user.userType == .Provider ? nil : user
        let provider: User? = user.userType == .Provider ? user : nil
        let call = Call(date: NSDate(), duration: 10*60, rating: 4, cost: 35.25, client: client, provider: provider)
        
        call.saveInBackgroundWithBlock { (success, error) in
            print("success \(success) call \(call)")
        }
    }
}