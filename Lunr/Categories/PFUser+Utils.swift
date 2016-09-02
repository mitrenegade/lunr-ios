import Foundation
import Parse

enum UserType: String {
    case Client
    case Provider
    // todo: Plumber, Electrician, Mechanic, etc?
}

protocol User {
    var name: String? { get }
    var displayString: String { get }
    var type: UserType { get }
    var callHistory: [Call] { get }
}

struct Card {
    // Placeholder for Card that needs to be associated with payments and calls
    var type: String
    var last4: String
}

struct Call {
    var date: NSDate
    var caller: PFUser
    var cost: Double
    var paymentMethod: Card
}

protocol PFProvider {
    var rating: Double? { get }
    var info: String? { get }
    var ratePerMin: Double? { get }
    var available: Bool { get }
    
    var reviews: [PFObject]? { get }
    var skills: [String]? { get }
}

protocol PFClient {
    var payment: PFObject? { get }
}

// MARK: Query/web APIs
extension PFUser {
    class func queryProviders(completionHandler: ((providers:[PFUser]?) -> Void), errorHandler: ((error: NSError?)->Void)) {
        let query = PFUser.query()
        query?.whereKeyExists("type")
        query?.whereKey("type", notEqualTo: UserType.Client.rawValue)
        query?.findObjectsInBackgroundWithBlock { (results, error) -> Void in
            if let error = error {
                errorHandler(error: error)
                return
            }
            
            let users = results as? [PFUser]
            completionHandler(providers: users)
        }
    }
}

extension PFUser: User {
    var name: String? {
        return self.username
    }

    var displayString: String {
        get {
            if let name = self.username {
                return name
            }
            else if let email = self.email {
                return email
            }
            
            if self.type == .Provider {
                return "a provider"
            }
            
            return "a client"
        }
    }
    
    var type: UserType {
        get {
            let types: [UserType] = [.Provider, .Client]
            for type in types {
                if type.rawValue.lowercaseString == (self.objectForKey("type") as? String)?.lowercaseString {
                    return type
                }
            }
            
            return .Client
        }
    }

    var callHistory: [Call] {
        get {
            // TODO: Pull call history from network
            let dummyCall = Call(date: NSDate(), caller: self, cost: 18.50, paymentMethod: Card(type: "VISA", last4: "1112"))
            return [dummyCall]
        }
    }
}

extension PFUser: PFClient {
    // Client only
    var payment: PFObject? {
        return nil // TODO: relationship for another PFObject class
    }
    
}

extension PFUser: PFProvider {

    // Provider only
    var rating: Double? {
        return self.objectForKey("rating") as? Double // TODO: calculate rating based on all ratings?
    }
    
    var info: String? {
        return self.objectForKey("info") as? String
    }
    
    var ratePerMin: Double? {
        return self.objectForKey("ratePerMin") as? Double
    }
    
    var available: Bool {
        return self.objectForKey("available") as? Bool ?? false
    }
    
    var reviews: [PFObject]? {
        return [] // todo: relationship with another PFObject class
    }
    
    var skills: [String]? {
        return []
    }
    
}

