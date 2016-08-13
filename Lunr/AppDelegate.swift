import UIKit
import Parse
import ParseFacebookUtilsV4
import FBSDKCoreKit
import Quickblox

let LOCAL_TEST = false
let TEST = false

let PARSE_APP_ID: String = "KAu5pzPvmjrFNdIeaB5zYb2la2Fs2zRi2JyuQZnA"
let PARSE_SERVER_URL_LOCAL: String = "http://localhost:1337/parse"
let PARSE_SERVER_URL = "https://lunr-server.herokuapp.com/parse"
let PARSE_CLIENT_KEY = "unused"

let QB_APP_ID: UInt = 45456
let QB_AUTH_KEY = "Ts3YVE7kHKUcYA3"
let QB_ACCOUNT_KEY = ""
let QB_AUTH_SECRET = "DptKZexBTDjhNt3"

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        let configuration = ParseClientConfiguration {
            $0.applicationId = PARSE_APP_ID
            $0.clientKey = PARSE_CLIENT_KEY
            $0.server = LOCAL_TEST ? PARSE_SERVER_URL_LOCAL : PARSE_SERVER_URL
        }

        Parse.initializeWithConfiguration(configuration)

        // Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions);

        // QuickBlox
        QBSettings.setApplicationID(QB_APP_ID)
        QBSettings.setAuthKey(QB_AUTH_KEY)
        QBSettings.setAccountKey(QB_ACCOUNT_KEY)
        QBSettings.setAuthSecret(QB_AUTH_SECRET)

        // force root window to appear
        self.window?.makeKeyAndVisible()

        // This call demonstrates the way to use services
        PFUser.queryProviders({ (providers) in
            print("Providers received: \(providers)")
        }) { (error) in
            print("Error \(error)")
        }

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    // MARK: - Navigation
    func startup() {
        // Login
        if let _ = PFUser.currentUser() {
            // user is logged in
//            self.goToMenu()
            self.goToProviderList()
        }
        else {
            self.goToSignupLogin()
        }
    }

    func goToSignupLogin() {
        let controller = UIStoryboard(name: "Login", bundle: nil).instantiateViewControllerWithIdentifier("FacebookViewController") as! FacebookViewController
        self.window?.rootViewController?.presentViewController(controller, animated: true, completion: nil)
        self.listenFor("login:success", action: #selector(didLogin), object: nil)
    }

    func didLogin() {
        print("logged in")
        self.stopListeningFor("login:success")

        // first dismiss login/signup flow
        self.window?.rootViewController?.dismissViewControllerAnimated(true, completion: {
            // load main flow
            //self.goToMenu()
            self.goToProviderList()
        })
    }

    func goToMenu() {
        guard let nav = UIStoryboard(name: "Provider", bundle: nil).instantiateInitialViewController() as? UINavigationController else { return }

        self.window?.rootViewController?.presentViewController(nav, animated: true, completion: nil)
        self.listenFor("logout:success", action: #selector(didLogout), object: nil)
    }

    func goToProviderList() {
        guard let nav = UIStoryboard(name: "Provider", bundle: nil).instantiateInitialViewController() as? UINavigationController else { return }

        self.window?.rootViewController?.presentViewController(nav, animated: true, completion: nil)
    }

    func didLogout() {
        print("logged out")
        self.stopListeningFor("logout:Success")

        // first dismiss main app
        self.window?.rootViewController?.dismissViewControllerAnimated(true, completion: {
            // load main flow
            self.goToSignupLogin()
        })
    }

}
