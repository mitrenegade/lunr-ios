//
//  Conversation.swift
//  Lunr
//
//  Created by Bobby Ren on 12/3/16.
//  Copyright © 2016 RenderApps. All rights reserved.
//

import UIKit
import Parse

enum ConversationStatus: String {
    case new
    case current
    case done
}

class Conversation: PFObject {
    @NSManaged var dialogId: String?
    
    @NSManaged var clientId: String?
    @NSManaged var providerId: String?
    @NSManaged var status: String?
}

extension Conversation: PFSubclassing {
    static func parseClassName() -> String {
        return "Conversation"
    }
}

extension Conversation {
    class func loadConversations(user: PFUser, completion: ((_ results: [Conversation]?, _ error: NSError?)->Void)?) {
        
    }
    
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        return df
    }
    
    var dateString: String {
        guard let date = self.updatedAt else { return "Today" }
        let beginningOfDay = Calendar.current.startOfDay(for: NSDate() as Date)
        if date.timeIntervalSince(beginningOfDay) > 0 {
            return "Today"
        }
        return dateFormatter.string(from: date)
    }
    
    var lastMessage: String {
        // todo
        return "Hello"
    }
    
}

