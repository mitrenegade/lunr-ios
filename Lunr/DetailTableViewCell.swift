//
//  DetailTableViewCell.swift
//  Lunr
//
//  Created by Randall Spence on 8/6/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class DetailTableViewCell: UITableViewCell {
    // TODO: Change to type providerInfoView after merging with Amy
    @IBOutlet weak var providerInfoView: UIView!
    @IBOutlet weak var textView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
}