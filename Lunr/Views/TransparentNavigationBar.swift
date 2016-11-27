//
//  TransparentNavigationBar.swift
//  Lunr
//
//  Created by Brent Raines on 10/16/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class TransparentNavigationBar: UINavigationBar {
    override func awakeFromNib() {
        super.awakeFromNib()
        setBackgroundImage(UIImage(), for: .default)
        isTranslucent = true
        backgroundColor = UIColor.clear
    }
}
