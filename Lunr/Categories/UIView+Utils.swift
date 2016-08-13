import UIKit

extension UIView {

    func addShadow() {
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSizeMake(0, 1.5)
        self.layer.shadowRadius = 3
        self.layer.shadowOpacity = 0.4
    }
}
