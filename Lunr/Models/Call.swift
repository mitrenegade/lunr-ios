//
//  CallService.swift
//  Lunr
//
//  Created by Bobby Ren on 8/30/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Parse
import Foundation

class Call: PFObject {
    // PFSubclassing and NSManaged is required so that PFObject.init() can be used, and PFObject's getters and setters correctly set key-value pairs that save to Parse
    @NSManaged var date: NSDate?
    @NSManaged var duration: NSNumber?
    @NSManaged var rating: NSNumber?
    @NSManaged var totalCost: NSNumber?
    @NSManaged var client: PFUser?
    @NSManaged var provider: PFUser?
    
    //var paymentMethod: Card

    init(date: NSDate, duration: Double, rating: Double, cost: Double, client: PFUser?, provider: PFUser?) {
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

extension Call: PFSubclassing {
    static func parseClassName() -> String {
        return "Call"
    }
}

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