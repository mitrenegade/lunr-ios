//
//  QBChatMessage+LunrExtensions.swift
//  Lunr
//
//  Created by Brent Raines on 9/19/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Foundation
import Quickblox

extension QBChatMessage {
    enum MessageType: UInt {
        case Text = 0
        case CreateGroupDialog = 1
        case UpdateGroupDialog = 2
        case ContactRequest = 4
        case AcceptContactRequest
        case RejectContactRequest
        case DeleteContactRequest
    }
}