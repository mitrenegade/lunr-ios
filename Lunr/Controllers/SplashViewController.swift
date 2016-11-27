import UIKit
import Parse

class SplashViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listenFor(.LoginSuccess, action: #selector(didLogin), object: nil)
        listenFor(.LogoutSuccess, action: #selector(didLogout), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // make sure user exists
        QBUserService.sharedInstance.refreshUserSession { (success) in
            print("success: \(success)")
        }
        
        goHome()
    }

    func goHome() {
        guard let homeViewController = homeViewController() else { return }
        if let presented = presentedViewController {
            guard homeViewController != presented else { return }
            dismiss(animated: true, completion: nil)
        } else {
            present(homeViewController, animated: true, completion: nil)
        }
    }
    
    fileprivate func homeViewController() -> UIViewController? {
        switch PFUser.current() {
        case .none:
            return UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController()
        case .some(let user as User):
            user.fetchInBackground()
            if user.isProvider {
                return UIStoryboard(name: "ProviderFlow", bundle: nil).instantiateInitialViewController()
            }
            
            return UIStoryboard(name: "ClientFlow", bundle: nil).instantiateInitialViewController()
        default:
            // PFUser.currentUser is only a PFUser. This case should not exist
            return UIStoryboard(name: "ClientFlow", bundle: nil).instantiateInitialViewController()
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
