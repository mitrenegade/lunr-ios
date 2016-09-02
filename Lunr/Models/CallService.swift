//
//  CallService.swift
//  Lunr
//
//  Created by Bobby Ren on 8/30/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Parse
import Foundation

/*
struct Call {
    var date: NSDate
    var caller: PFUser
    var cost: Double
    var paymentMethod: Card
}
*/

class Call: PFObject, PFSubclassing {
    // PFSubclassing and NSManaged is required so that PFObject.init() can be used, and PFObject's getters and setters correctly set key-value pairs that save to Parse
    @NSManaged var date: NSDate?
    @NSManaged var duration: NSNumber?
    @NSManaged var rating: NSNumber?
    @NSManaged var totalCost: NSNumber?
    @NSManaged var client: PFUser?
    @NSManaged var provider: PFUser?
    
    init(date: NSDate, duration: Int, rating: Int, cost: Double, client: PFUser?, provider: PFUser?) {
        super.init()

        self.date = date
        self.duration = duration
        self.rating = rating
        self.totalCost = cost
        
        // TODO: client and provider must exist
        self.client = client
        self.provider = provider
    }
}

extension Call {
    static func parseClassName() -> String {
        return "Call"
    }
}

class CallService: NSObject {
    static let sharedInstance: CallService = CallService()
    
    func createTestCallInParse() {
        Call.registerSubclass()
        
        guard let user = PFUser.currentUser() else { return }
        
        let client: PFUser? = user.type == .Provider ? nil : user
        let provider: PFUser? = user.type == .Provider ? user : nil
        let call = Call(date: NSDate(), duration: 10*60, rating: 4, cost: 35.25, client: client, provider: provider)
        
        call.saveInBackgroundWithBlock { (success, error) in
            print("success \(success) call \(call)")
        }
    }
}