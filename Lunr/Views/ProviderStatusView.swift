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
        case offline
        case online
        case newRequest(QBUUser) // user, dialogId
    }
    
    var status: ProviderStatus = .offline {
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
    
    fileprivate func setup() {
        axis = .vertical
        alignment = .center
        distribution = .fillProportionally
        spacing = 20
    }
    
    fileprivate func refresh() {
        UIView.animate(withDuration: 0.2, animations: { [weak self] _ in
            self?.arrangedSubviews.forEach { sv in
                sv.alpha = 0
            }
            }, completion: { [weak self] _ in
                self?.removeAllArrangedSubviews()
                guard let strongSelf = self else { return }
                switch strongSelf.status {
                case .offline:
                    strongSelf.addArrangedSubview(strongSelf.label("You are currently offline."))
                    strongSelf.addArrangedSubview(strongSelf.icon("offline"))
                case .online:
                    strongSelf.addArrangedSubview(strongSelf.label("Currently waiting for requests..."))
                    strongSelf.addArrangedSubview(strongSelf.icon("hourglass"))
                case .newRequest(let user):
                    strongSelf.addArrangedSubview(strongSelf.label("New call request"))
                    strongSelf.addArrangedSubview(strongSelf.label("\(user.fullName!) has sent you a message."))
                    strongSelf.addArrangedSubview(strongSelf.button(user))
                }
                UIView.animate(withDuration: 0.2, animations: { _ in
                    self?.arrangedSubviews.forEach { sv in
                        sv.alpha = 1
                    }
                })
        })
    }
    
    fileprivate func label(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.futuraMediumWithSize(12)
        label.textColor = UIColor(red:0.647, green:0.647, blue:0.647, alpha:1)
        label.textAlignment = .center
        label.alpha = 0
        
        return label
    }
    
    fileprivate func icon(_ imageName: String) -> UIImageView {
        let view = UIImageView()
        view.image = UIImage(named: imageName)
        view.contentMode = .scaleAspectFit
        view.alpha = 0
        
        return view
    }
    
    fileprivate func button(_ user: QBUUser) -> UIButton {
        let button = LunrRoundActivityButton()
        button.setTitle("Reply", for: UIControlState())
        button.backgroundColor = UIColor.lunr_darkBlue()
        button.setTitleColor(UIColor.white, for: UIControlState())
        button.alpha = 0
        button.addTarget(self, action: #selector(didClickReply), for: .touchUpInside)
        
        return button
    }
    
    @objc fileprivate func didClickReply() {
        self.delegate?.didClickReply()
    }
}
