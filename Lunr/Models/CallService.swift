//
//  CallService.swift
//  Lunr
//
//  Created by Bobby Ren on 8/30/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Parse
import Foundation

class Call: PFObject, PFSubclassing {
    // PFSubclassing and NSManaged is required so that PFObject.init() can be used, and PFObject's getters and setters correctly set key-value pairs that save to Parse
    @NSManaged var date: NSDate?
    @NSManaged var duration: NSNumber?
    @NSManaged var rating: NSNumber?
    @NSManaged var totalCost: NSNumber?
    @NSManaged var client: PFUser?
    @NSManaged var provider: PFUser?
}

extension Call {
    static func parseClassName() -> String {
        return "Call"
    }
}

class CallService: NSObject {
    static let sharedInstance: CallService = CallService()
    
    func createCall() {
        Call.registerSubclass()
        
        guard let user = PFUser.currentUser() else { return }
        
        let call = Call()
        call.date = NSDate()
        call.duration = 30*60
        call.rating = 4
        call.totalCost = 40.25
        call.client = user.type == .Provider ? nil : user
        call.provider = user.type == .Provider ? user : nil
        
        call.saveInBackgroundWithBlock { (success, error) in
            print("success \(success) call \(call)")
        }
    }
}