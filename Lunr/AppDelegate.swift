import UIKit
import Parse
import ParseFacebookUtilsV4
import FBSDKCoreKit
import Quickblox
import Fabric
import Crashlytics

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

        // App wide appearance protocols
        setGlobalAppearanceAttributes()
        
        Fabric.with([Crashlytics.self])

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
    
    // MARK: Appearance
    private func setGlobalAppearanceAttributes() {
        // UITabBar
        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.barTintColor = UIColor.lunr_darkBlue()
        tabBarAppearance.tintColor = UIColor.whiteColor()
        
        // UITabBarItem
        let tabBarItemAppearance = UITabBarItem.appearance()
        
        var normalTabBarItemTextAttr = tabBarItemAppearance.titleTextAttributesForState(.Normal) ?? [String:AnyObject]()
        normalTabBarItemTextAttr[NSForegroundColorAttributeName] = UIColor.whiteColor()
        normalTabBarItemTextAttr[NSFontAttributeName] = UIFont.futuraMediumWithSize(17)
        tabBarItemAppearance.setTitleTextAttributes(normalTabBarItemTextAttr, forState: .Selected)
        
        var selectedTabBarItemTextAttr = tabBarItemAppearance.titleTextAttributesForState(.Selected) ?? [String:AnyObject]()
        selectedTabBarItemTextAttr[NSForegroundColorAttributeName] = UIColor.lunr_blueText()
        tabBarItemAppearance.setTitleTextAttributes(selectedTabBarItemTextAttr, forState: .Selected)
    }
    
    // MARK: Push
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let deviceIdentifier: String = UIDevice.currentDevice().identifierForVendor!.UUIDString

        let subscription: QBMSubscription! = QBMSubscription()
        subscription.notificationChannel = QBMNotificationChannel.APNS
        subscription.deviceUDID = deviceIdentifier
        subscription.deviceToken = deviceToken
        QBRequest.createSubscription(subscription, successBlock: { (response: QBResponse!, objects: [QBMSubscription]?) -> Void in
            // success
            print("Subscription created: \(objects)")
            
            QBUserService.sharedInstance.updateUserPushTag()
            
        }) { (response: QBResponse!) -> Void in
            // error
            print("Error response: \(response)")
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        NSLog("Push failed to register with error: %@", error)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        NSLog("my push is: %@", userInfo)
        if application.applicationState == UIApplicationState.Inactive {
            print("Inactive")
        }
        
        guard let dialogID = userInfo["dialogId"] as? String else {
            return
        }
        
        guard !dialogID.isEmpty else {
            return
        }
        
        /*
        let dialogWithIDWasEntered: String? = ServicesManager.instance().currentDialogID
        if dialogWithIDWasEntered == dialogID {
            return
        }
         */
        
        QBNotificationService.sharedInstance.pushDialogID = dialogID
        
        // calling dispatch async for push notification handling to have priority in main queue
        dispatch_async(dispatch_get_main_queue(), {
            QBNotificationService.sharedInstance.handlePushNotification(dialogID)
        });
    }
}

