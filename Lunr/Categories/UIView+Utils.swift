import UIKit

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius ?? 0.0
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0.0
        }
    }

    func addShadow() {
        self.layer.masksToBounds = false
        self.layer.shadowOffset = CGSizeMake(0, 1.5)
        self.layer.shadowRadius = 3
        self.layer.shadowOpacity = 0.4
    }
}
