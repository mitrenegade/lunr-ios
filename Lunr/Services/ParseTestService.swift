//
//  ParseTestService.swift
//  Lunr
//
//  Created by Bobby Ren on 12/13/16.
//  Copyright © 2016 RenderApps. All rights reserved.
//

import UIKit
import Parse

enum TestAlertType: String {
    case GenericTestAlert
    case ConversationSaveFailed
}

extension UIViewController {
    func testAlert(_ title: String, message: String?, type: TestAlertType? = .GenericTestAlert, params: [String: Any]?, completion: (() -> Void)? = nil) {
        
        let object = PFObject(className: "TestLog")
        object.setValue(PFUser.current()?.objectId, forKey: "userId")
        if let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"]
        {
            object.setValue(version, forKey: "version")
        }
        if let build = Bundle.main.infoDictionary!["CFBundleVersion"]
        {
            object.setValue(build, forKey: "build")
        }
        object.setValue(TestAlertType.ConversationSaveFailed.rawValue, forKey: "type")
        object.setValue(title, forKey: "title")
        object.setValue(message, forKey: "message")
        if let params = params {
            object.setValue(params, forKey:"params")
        }
        object.saveInBackground()
        
        guard TEST else {
            return
        }
        
        self.simpleAlert(title, message: "Error type: \(type!.rawValue) \(message ?? "")", completion: completion)

    }
}
