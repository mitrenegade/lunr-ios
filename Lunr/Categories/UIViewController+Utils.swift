import UIKit

extension UIViewController {
    
    func simpleAlert(_ title: String, defaultMessage: String?, error: NSError?, completion: (() -> Void)? = nil) {
        if let msg = error?.userInfo["error"] as? String {
            self.simpleAlert(title, message: msg, completion: completion)
            return
        }
        else if let msg = error?.userInfo["NSLocalizedDescription"] as? String {
            self.simpleAlert(title, message: msg, completion: completion)
            return
        }

        self.simpleAlert(title, message: defaultMessage, completion: completion)
    }
    
    func simpleAlert(_ title: String, message: String?, completion: (() -> Void)? = nil) {
        let alert: UIAlertController = UIAlertController.simpleAlert(title, message: message, completion: completion)
        self.present(alert, animated: true, completion: nil)
    }
}

extension NSObject {
    func appDelegate() -> AppDelegate {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate
    }
    
    // MARK: - Notifications
    func listenFor(_ notification: NotificationType, action: Selector, object: AnyObject?) {
        listenFor(notification.rawValue, action: action, object: object)
    }
    
    func listenFor(_ notificationName: String, action: Selector, object: AnyObject?) {
        NotificationCenter.default.addObserver(self, selector: action, name: NSNotification.Name(rawValue: notificationName), object: object)
    }
    
    func stopListeningFor(_ notification: NotificationType) {
        stopListeningFor(notification.rawValue)
    }
    
    func stopListeningFor(_ notificationName: String) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: notificationName), object: nil)
    }
    
    func notify(_ notification: NotificationType, object: AnyObject? = nil, userInfo: [AnyHashable: Any]? = nil) {
        notify(notification.rawValue, object: object, userInfo: userInfo)
    }
    
    func notify(_ notificationName: String, object: AnyObject?, userInfo: [AnyHashable: Any]?) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: notificationName), object: object, userInfo: userInfo)
    }
    
    func wait(_ delay:Double, then:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: then)
    }
}

extension UIAlertController {
    class func simpleAlert(_ title: String, message: String?, completion: (() -> Void)?) -> UIAlertController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.view.tintColor = UIColor.black
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            print("cancel")
            if completion != nil {
                completion!()
            }
        }))
        return alert
    }
}
