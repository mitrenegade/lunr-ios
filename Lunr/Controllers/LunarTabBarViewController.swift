//
//  LunarTabBarViewController.swift
//  Lunr
//
//  Created by Brent Raines on 10/10/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class LunarTabBarViewController: UITabBarController {
    let tabBarHeight: CGFloat = 60
    
    override func viewWillLayoutSubviews() {
        let heightDiff = tabBar.frame.height - tabBarHeight
        guard heightDiff != 0 else { return }
        tabBar.frame.origin.y += (heightDiff)
        tabBar.frame.size.height = tabBarHeight
        tabBar.items?.forEach { item in
            item.titlePositionAdjustment.vertical = heightDiff / 2
        }
    }
}
