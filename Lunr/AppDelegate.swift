//
//  AppDelegate.swift
//  Lunr
//
//  Created by Bobby Ren on 8/5/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import ParseFacebookUtilsV4
import FBSDKCoreKit

let LOCAL_TEST = false

let PARSE_APP_ID: String = "KAu5pzPvmjrFNdIeaB5zYb2la2Fs2zRi2JyuQZnA"
let PARSE_SERVER_URL_LOCAL: String = "http://localhost:1337/parse"
let PARSE_SERVER_URL = "https://lunr-server.herokuapp.com/parse"
let PARSE_CLIENT_KEY = "unused"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        // Parse
        let configuration = ParseClientConfiguration {
            $0.applicationId = PARSE_APP_ID
            $0.clientKey = PARSE_CLIENT_KEY
            $0.server = LOCAL_TEST ? PARSE_SERVER_URL_LOCAL : PARSE_SERVER_URL
        }
        Parse.initializeWithConfiguration(configuration)

        // Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions);
        
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

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
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
            self.goToMenu()
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
            self.goToMenu()
        })
    }
    
    func goToMenu() {
        guard let controller: ViewController = UIStoryboard(name: "Bobby", bundle: nil).instantiateViewControllerWithIdentifier("ViewController") as? ViewController else {
            return
        }
        
        self.window?.rootViewController?.presentViewController(controller, animated: true, completion: nil)
        self.listenFor("logout:success", action: #selector(didLogout), object: nil)
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

