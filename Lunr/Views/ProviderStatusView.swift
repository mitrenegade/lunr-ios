//
//  ProviderStatusView.swift
//  Lunr
//
//  Created by Brent Raines on 10/10/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class ProviderStatusView: UIStackView {
    enum ProviderStatus {
        case Offline
        case Online
        case NewRequest(User)
    }
    
    var status: ProviderStatus = .Offline {
        didSet {
            refresh()
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
        alignment = .Fill
        distribution = .Fill
        spacing = 20
        axis = .Vertical
    }
    
    private func refresh() {
        removeAllArrangedSubviews()
        
        switch status {
        case .Offline:
            addArrangedSubview(label("You are currently offline."))
            addArrangedSubview(icon("offline"))
        case .Online:
            addArrangedSubview(label("Currently waiting for requests..."))
            addArrangedSubview(icon("hourglass"))
        case .NewRequest(let user):
            addArrangedSubview(label("New call request"))
            addArrangedSubview(label("\(user.firstName) has sent you a message."))
            addArrangedSubview(button(user))
        }
    }
    
    private func label(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.futuraMediumWithSize(12)
        label.textColor = UIColor(red:0.647, green:0.647, blue:0.647, alpha:1)
        label.textAlignment = .Center
        
        return label
    }
    
    private func icon(imageName: String) -> UIImageView {
        let view = UIImageView()
        view.image = UIImage(named: imageName)
        view.contentMode = .ScaleAspectFit
        
        return view
    }
    
    private func button(user: User) -> UIButton {
        let button = LunrActivityButton()
        button.setTitle("Reply", forState: .Normal)
        button.titleLabel?.font = UIFont.futuraMediumWithSize(16)
        button.backgroundColor = UIColor.lunr_darkBlue()
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.cornerRadius = button.bounds.height / 2
        
        return button
    }
}
