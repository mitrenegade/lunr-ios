//
//  IncomingCallCell.swift
//  Lunr
//
//  Created by Bobby Ren on 12/3/16.
//  Copyright © 2016 RenderApps. All rights reserved.
//

import UIKit

class IncomingCallCell: UITableViewCell {

    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelTime: UILabel!
    @IBOutlet weak var labelMessage: UILabel!
    
    func configure(conversation: Conversation) {
        labelName.text = conversation.clientName ?? "Someone"
        labelMessage.text = conversation.lastMessage ?? "..."
        labelTime.text = conversation.dateString
    }
}
