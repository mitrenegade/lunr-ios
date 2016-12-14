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
    case RefreshIncomingCallsFailed
    case InvalidConversationSelected
    case NotifyForVideoFailed
    case ProviderClickedIncomingCallFailed
}

extension UIViewController {
    func testAlert(_ title: String, message: String?, type: TestAlertType, error: Error? = nil, params: [String: Any]? = nil, completion: (() -> Void)? = nil) {
        
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
        object.setValue(type.rawValue, forKey: "type")
        object.setValue(title, forKey: "title")
        object.setValue(message, forKey: "message")
        if let params = params {
            object.setValue(params, forKey:"params")
        }
        if let error = error as? NSError {
            object.setValue(error.localizedDescription, forKey: "error")
        }
        object.saveInBackground()
        
        guard TEST else {
            return
        }
        
        self.simpleAlert(title, message: "Error type: \(type.rawValue) \(message ?? "")", completion: completion)

    }
}
