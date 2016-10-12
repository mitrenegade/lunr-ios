//
//  LunrRoundActivityButton.swift
//  Lunr
//
//  Created by Bobby Ren on 10/11/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//


import UIKit

class LunrRoundActivityButton: LunrActivityButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        cornerRadius = bounds.height / 2
    }
    
    func setup() {
        widthAnchor.constraintEqualToConstant(150).active = true
        heightAnchor.constraintEqualToConstant(40).active = true
        
        titleEdgeInsets = UIEdgeInsetsZero
        contentEdgeInsets = UIEdgeInsetsZero
        titleLabel?.font = UIFont.futuraMediumWithSize(16)
        setTitle("", forState: .Disabled)
        
        activity.hidesWhenStopped = true
        activity.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activity)
        activity.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        activity.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
    }
}
