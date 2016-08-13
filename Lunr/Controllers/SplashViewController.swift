import UIKit

class SplashViewController: UIViewController {

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.appDelegate().startup()
    }
}
