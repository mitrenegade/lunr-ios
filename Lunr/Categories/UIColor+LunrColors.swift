import UIKit

extension UIColor {
    class func lunr_darkBlue() -> UIColor {
        return UIColor(red: 41/255, green: 44/255, blue: 84/255, alpha: 1.0)
    }

    class func lunr_beige() -> UIColor {
        return UIColor(red: 243/255, green: 244/255, blue: 245/255, alpha: 1.0)
    }

    class func lunr_grayText() -> UIColor {
        return UIColor(red: 148/255, green: 148/255, blue: 148/255, alpha: 1.0)
    }

    class func lunr_darkGrayText() -> UIColor {
        return UIColor(red: 46/255, green: 56/255, blue: 91/255, alpha: 1.0)
    }

    class func lunr_iceBlue() -> UIColor {
        return UIColor(red: 249/255, green: 255/255, blue: 254/255, alpha: 1.0)
    }

    class func lunr_lightBlue() -> UIColor {
        return UIColor(red: 199/255, green: 211/255, blue: 236/255, alpha: 1.0)
    }

    class func lunr_separatorGray() -> UIColor {
        return UIColor(red: 208/255, green: 211/255, blue: 210/255, alpha: 0.8)
    }
    
    class func lunr_blueText() -> UIColor {
        return UIColor(red:0.780,  green:0.827,  blue:0.929, alpha:1)
    }
    
    
    // Custom chat message bubble colors based on index of user
    @nonobjc static let qbChatColors = [
        UIColor(red: 0.992, green:0.510, blue:0.035, alpha:1.000),
        UIColor(red: 0.039, green:0.376, blue:1.000, alpha:1.000),
        UIColor(red: 0.984, green:0.000, blue:0.498, alpha:1.000),
        UIColor(red: 0.204, green:0.644, blue:0.251, alpha:1.000),
        UIColor(red: 0.580, green:0.012, blue:0.580, alpha:1.000),
        UIColor(red: 0.396, green:0.580, blue:0.773, alpha:1.000),
        UIColor(red: 0.765, green:0.000, blue:0.086, alpha:1.000),
        UIColor.redColor(),
        UIColor(red: 0.786, green:0.706, blue:0.000, alpha:1.000),
        UIColor(red: 0.740, green:0.624, blue:0.797, alpha:1.000)
    ]
}
