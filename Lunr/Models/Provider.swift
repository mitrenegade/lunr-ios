import Foundation

struct Review {
    let text : String
    let rating : Double

    init(rating: Double, text: String) {
        self.rating = rating
        self.text = text
    }
}

class Provider : NSObject {
    let name : String
    let rating : Double
    let reviews : [Review]
    let ratePerMin : Double
    var available : Bool = true
    let skills : [String]
    let info : String

    init(name: String, rating: Double, reviews: [Review], ratePerMin : Double, skills: [String], info: String) {
        self.name = name
        self.rating = rating
        self.reviews = reviews
        self.ratePerMin = ratePerMin
        self.skills = skills
        self.info = info
    }
}
