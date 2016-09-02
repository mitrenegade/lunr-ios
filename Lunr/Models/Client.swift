//
//  Client.swift
//  Lunr
//
//  Created by Bobby Ren on 9/2/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class Client: User {
    @NSManaged var payment: PaymentMethod?
}

extension Client {
    override static func parseClassName() -> String {
        return "Client"
    }
}
