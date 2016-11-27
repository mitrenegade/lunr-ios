import UIKit
import Parse
import ParseFacebookUtilsV4
import FBSDKCoreKit
import Quickblox
import Fabric
import Crashlytics
import Stripe
import QMChatViewController

let LOCAL_TEST = false
let TEST = false

let PARSE_APP_ID: String = "KAu5pzPvmjrFNdIeaB5zYb2la2Fs2zRi2JyuQZnA"
let PARSE_SERVER_URL_LOCAL: String = "http://localhost:1337/parse"
let PARSE_SERVER_URL = "https://lunr-server.herokuapp.com/parse"
let PARSE_CLIENT_KEY = "unused"

let QB_APP_ID: UInt = 45456
let QB_AUTH_KEY = "Ts3YVE7kHKUcYA3"
let QB_ACCOUNT_KEY = "qezMRGfSugu3WHCiT1wg"
let QB_AUTH_SECRET = "DptKZexBTDjhNt3"

let STRIPE_KEY_DEV = "pk_test_YYNWvzYJi3bTyOJi2SNK3IkE"

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let configuration = ParseClientConfiguration {
            $0.applicationId = PARSE_APP_ID
            $0.clientKey = PARSE_CLIENT_KEY
            $0.server = LOCAL_TEST ? PARSE_SERVER_URL_LOCAL : PARSE_SERVER_URL
        }

        Parse.initialize(with: configuration)

        // Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        PFFacebookUtils.initializeFacebook(applicationLaunchOptions: launchOptions);

        // QuickBlox
        QBSettings.setApplicationID(QB_APP_ID)
        QBSettings.setAuthKey(QB_AUTH_KEY)
        QBSettings.setAccountKey(QB_ACCOUNT_KEY)
        QBSettings.setAuthSecret(QB_AUTH_SECRET)

        // force root window to appear
        self.window?.makeKeyAndVisible()

        // App wide appearance protocols
        setGlobalAppearanceAttributes()
        
        Fabric.with([Crashlytics.self])

        STPPaymentConfiguration.shared().publishableKey = STRIPE_KEY_DEV
        STPPaymentConfiguration.shared().smsAutofillDisabled = true
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    // MARK: Appearance
    fileprivate func setGlobalAppearanceAttributes() {
        // UINavBar
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.tintColor = UIColor(red:0.200, green:0.200, blue:0.200, alpha:1)
        var navBarTitleAttr = navBarAppearance.titleTextAttributes ?? [String:AnyObject]()
        navBarTitleAttr[NSFontAttributeName] = UIFont.futuraMediumWithSize(16)
        navBarTitleAttr[NSForegroundColorAttributeName] = UIColor(red:0.200, green:0.200, blue:0.200, alpha:1)
        navBarAppearance.titleTextAttributes = navBarTitleAttr
        
        // UITabBar
        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.barTintColor = UIColor(red:0.180, green:0.220, blue:0.357, alpha:1)
        tabBarAppearance.tintColor = UIColor(red:0.780, green:0.827, blue:0.933, alpha:1)
        
        // UITabBarItem
        let tabBarItemAppearance = UITabBarItem.appearance()
        
        var normalTabBarItemTextAttr = tabBarItemAppearance.titleTextAttributes(for: UIControlState()) ?? [String:AnyObject]()
        normalTabBarItemTextAttr[NSForegroundColorAttributeName] = UIColor(red:0.961, green:0.965, blue:0.969, alpha:1)
        normalTabBarItemTextAttr[NSFontAttributeName] = UIFont.futuraMediumWithSize(12)
        tabBarItemAppearance.setTitleTextAttributes(normalTabBarItemTextAttr, for: UIControlState())
        
        var selectedTabBarItemTextAttr = tabBarItemAppearance.titleTextAttributes(for: .selected) ?? [String:AnyObject]()
        selectedTabBarItemTextAttr[NSForegroundColorAttributeName] = UIColor(red:0.780, green:0.827, blue:0.933, alpha:1)
        tabBarItemAppearance.setTitleTextAttributes(selectedTabBarItemTextAttr, for: .selected)
    }
    
    // MARK: Push
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushService().registerQBPushSubscription(deviceToken) { (success) in
            print("push subscription success: \(success)")
            self.notify(NotificationType.Push.Registered.rawValue, object: nil, userInfo: nil)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("Push failed to register with error: %@", error)
        self.notify(NotificationType.Push.Registered.rawValue, object: nil, userInfo: nil)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        NSLog("my push is: %@", userInfo)
        if application.applicationState == UIApplicationState.inactive {
            print("Inactive")
            self.notify(NotificationType.Push.ReceivedInBackground.rawValue, object: nil, userInfo: nil)
        }
        
        QBNotificationService.sharedInstance.handlePushNotification(userInfo)
    }
}

