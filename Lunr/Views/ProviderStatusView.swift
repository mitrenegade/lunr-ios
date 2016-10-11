//
//  ProviderStatusView.swift
//  Lunr
//
//  Created by Brent Raines on 10/10/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Quickblox

protocol ProviderStatusViewDelegate: class {
    func didClickReply()
}

class ProviderStatusView: UIStackView {
    weak var delegate: ProviderStatusViewDelegate?
    
    enum ProviderStatus {
        case Offline
        case Online
        case NewRequest(QBUUser) // user, dialogId
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
        distribution = .EqualCentering
        spacing = 20
        axis = .Vertical
    }
    
    private func refresh() {
        UIView.animateWithDuration(0.2, animations: { [weak self] _ in
            self?.arrangedSubviews.forEach { sv in
                sv.alpha = 0
            }
            }, completion: { [weak self] _ in
                self?.removeAllArrangedSubviews()
                guard let strongSelf = self else { return }
                switch strongSelf.status {
                case .Offline:
                    strongSelf.addArrangedSubview(strongSelf.label("You are currently offline."))
                    strongSelf.addArrangedSubview(strongSelf.icon("offline"))
                case .Online:
                    strongSelf.addArrangedSubview(strongSelf.label("Currently waiting for requests..."))
                    strongSelf.addArrangedSubview(strongSelf.icon("hourglass"))
                case .NewRequest(let user):
                    strongSelf.addArrangedSubview(strongSelf.label("New call request"))
                    strongSelf.addArrangedSubview(strongSelf.label("\(user.fullName!) has sent you a message."))
                    strongSelf.addArrangedSubview(strongSelf.button(user))
                }
                UIView.animateWithDuration(0.2, animations: { _ in
                    self?.arrangedSubviews.forEach { sv in
                        sv.alpha = 1
                    }
                })
        })
    }
    
    private func label(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.futuraMediumWithSize(12)
        label.textColor = UIColor(red:0.647, green:0.647, blue:0.647, alpha:1)
        label.textAlignment = .Center
        label.alpha = 0
        
        return label
    }
    
    private func icon(imageName: String) -> UIImageView {
        let view = UIImageView()
        view.image = UIImage(named: imageName)
        view.contentMode = .ScaleAspectFit
        view.alpha = 0
        
        return view
    }
    
    private func button(user: QBUUser) -> UIButton {
        let button = LunrActivityButton()
        button.setTitle("Reply", forState: .Normal)
        button.titleLabel?.font = UIFont.futuraMediumWithSize(16)
        button.backgroundColor = UIColor.lunr_darkBlue()
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.cornerRadius = button.bounds.height / 2
        button.alpha = 0
        button.addTarget(self, action: #selector(didClickReply), forControlEvents: .TouchUpInside)
        
        return button
    }
    
    @objc private func didClickReply() {
        self.delegate?.didClickReply()
    }
}
