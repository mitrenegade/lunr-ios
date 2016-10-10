//
//  UIStackView+LunrExtensions.swift
//  Lunr
//
//  Created by Brent Raines on 10/10/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

extension UIStackView {
    func removeAllArrangedSubviews() {
        for sv in arrangedSubviews {
            sv.removeFromSuperview()
        }
    }
}
