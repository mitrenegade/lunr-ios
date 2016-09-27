//
//  LunrActivityButton.swift
//  Lunr
//
//  Created by Brent Raines on 8/30/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class LunrActivityButton: UIButton {
    let activity = UIActivityIndicatorView(activityIndicatorStyle: .White)
    var busy: Bool = false {
        didSet {
            enabled = !busy
            if busy {
                activity.startAnimating()
            } else {
                activity.stopAnimating()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        setTitle("", forState: .Disabled)
        activity.hidesWhenStopped = true
        activity.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activity)
        activity.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        activity.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
    }
}
