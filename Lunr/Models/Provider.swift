import UIKit
import Parse

class Provider : User {
    @NSManaged var rating : Double
    @NSManaged var reviews : [Review]?
    @NSManaged var ratePerMin : Double
    @NSManaged var available : Bool
    @NSManaged var skills : [String]?
    @NSManaged var info : String

    init(firstName: String, lastName: String, rating: Double, reviews: [Review], ratePerMin : Double, skills: [String], info: String) {
        super.init()
        
        self.firstName = firstName
        self.lastName = lastName
        self.rating = rating
        self.reviews = reviews
        self.ratePerMin = ratePerMin
        self.skills = skills
        self.info = info
    }
}

extension Provider {
    override static func parseClassName() -> String {
        return "Provider"
    }
}

class ProviderService {
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