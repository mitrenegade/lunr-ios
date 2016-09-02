import UIKit
import Parse

class SplashViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listenFor(.LoginSuccess, action: #selector(didLogin), object: nil)
        listenFor(.LogoutSuccess, action: #selector(didLogout), object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        goHome()
    }

    func goHome() {
        guard let homeViewController = homeViewController() else { return }
        if let presented = presentedViewController {
            guard homeViewController != presented else { return }
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            presentViewController(homeViewController, animated: true, completion: nil)
        }
    }
    
    private func homeViewController() -> UIViewController? {
        switch PFUser.currentUser() {
        case .None:
            return UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController()
        case .Some(let user):
            if user.userType == .Provider {
                return UIStoryboard(name: "ProviderFlow", bundle: nil).instantiateInitialViewController()
            }
            return UIStoryboard(name: "Provider", bundle: nil).instantiateInitialViewController()
        }
    }

    func didLogin() {
        print("logged in")
        goHome()
    }
    
    func didLogout() {
        print("logged out")
        goHome()
    }
    
    deinit {
        stopListeningFor(.LoginSuccess)
        stopListeningFor(.LogoutSuccess)
    }
}
