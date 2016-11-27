//
//  LunrActivityButton.swift
//  Lunr
//
//  Created by Brent Raines on 8/30/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class LunrActivityButton: UIButton {
    let activity = UIActivityIndicatorView(activityIndicatorStyle: .white)
    var busy: Bool = false {
        didSet {
            isEnabled = !busy
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
    
    func setup() {
        setTitle("", for: .disabled)
        activity.hidesWhenStopped = true
        activity.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activity)
        activity.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activity.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
}
