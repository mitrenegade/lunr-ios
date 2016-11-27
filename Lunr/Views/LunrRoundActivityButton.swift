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
    
    override func setup() {
        widthAnchor.constraint(equalToConstant: 150).isActive = true
        heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        titleEdgeInsets = UIEdgeInsets.zero
        contentEdgeInsets = UIEdgeInsets.zero
        titleLabel?.font = UIFont.futuraMediumWithSize(16)
        setTitle("", for: .disabled)
        
        activity.hidesWhenStopped = true
        activity.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activity)
        activity.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        activity.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
}
