//
//  UserService.swift
//  Lunr
//
//  Created by Bobby Ren on 9/3/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Foundation
import Parse
import ParseLiveQuery

class UserService: NSObject {
    static let sharedInstance: UserService = UserService()
    
    class func logout() {
        PFUser.logOut()
        QBUserService.sharedInstance.logoutQBUser()
        sharedInstance.notify(.LogoutSuccess)
    }
    
    // live query for Parse objects
    let liveQueryClient = ParseLiveQuery.Client()
    var subscription: Subscription<User>?
    var subscribedToProviderUpdates: Bool = false
    var providers: [User]?
    
    let pageSize = 10
    func queryProvidersAtPage(_ page: Int = 0, filterOption: SortCategory = .alphabetical, searchTerms: [String] = [], ascending: Bool = true, availableOnly: Bool = false, completionHandler: @escaping ((_ providers:[PFUser]?) -> Void), errorHandler: @escaping ((_ error: NSError?)->Void)) {
        var ascending = ascending
        let query = PFUser.query()
        query?.whereKeyExists("type")
        query?.whereKey("type", notEqualTo: UserType.Client.rawValue.lowercased())
        query?.limit = pageSize
        query?.skip = page * pageSize
        if availableOnly {
            query?.whereKey("available", equalTo: true)
        }
        query?.addDescendingOrder("available") // always show available at top
        
        var filterKey = "lastName"
        switch filterOption {
        case .price:
            filterKey = "ratePerMin"
            break
        case .rating:
            filterKey = "rating"
            ascending = !ascending // feedback should be descending
        default:
            break
        }
        if ascending {
            query?.addAscendingOrder(filterKey)
        }
        else {
            query?.addDescendingOrder(filterKey)
        }
        
        // favorites
        if filterOption == .favorites {
            if let user = PFUser.current() as? User {
                query?.whereKey("objectId", containedIn: user.favorites)
            }
        }
        
        // search terms
        if searchTerms.count > 0 {
            print("Search terms: \(searchTerms)")
            // HACK: make capitalization insensitive by searching for both lowercased versions and first letter capitalization. The correct way to do this is to create an all lowercase canonical search field for each user

            let lowerCase = searchTerms.map{$0.lowercased()}
            let capitalized = searchTerms.map{$0.capitalized}
            
            let lastNameQuery = PFUser.query()!.whereKey("lastName", containedIn: lowerCase)
            let firstNameQuery = PFUser.query()!.whereKey("firstName", containedIn: lowerCase)
            let skillsQuery = PFUser.query()!.whereKey("skills", containedIn: lowerCase)
            let lastNameQueryCap = PFUser.query()!.whereKey("lastName", containedIn: capitalized)
            let firstNameQueryCap = PFUser.query()!.whereKey("firstName", containedIn: capitalized)
            let skillsQueryCap = PFUser.query()!.whereKey("skills", containedIn: capitalized)
            
            let orQuery = PFQuery.orQuery(withSubqueries: [lastNameQuery, firstNameQuery, skillsQuery,lastNameQueryCap, firstNameQueryCap, skillsQueryCap])
            
            query?.whereKey("objectId", matchesKey:"objectId", in: orQuery)
        }
        
        query?.findObjectsInBackground { (results, error) -> Void in
            if let error = error as? NSError {
                if error.code == 209 {
                    UserService.logout()
                }
                else {
                    errorHandler(error as NSError?)
                }
                return
            }
            
            let users = results as? [PFUser]
            self.providers = users as? [User]
            completionHandler(users)
        }
    }
    
    func queryReviewsForProvider(_ provider: User, completionHandler: @escaping ((_ reviews:[Review]?) -> Void), errorHandler: @escaping ((_ error: NSError?)->Void)) {
        let query = Review.query()
        query?.whereKey("provider", equalTo: provider)
        query?.order(byDescending: "createdAt")
        query?.findObjectsInBackground { (results, error) -> Void in
            if let error = error {
                errorHandler(error as NSError?)
                return
            }
            
            let reviews = results as? [Review]
            completionHandler(reviews)
        }
    }
    
    // MARK: Subscriptions
    func subscribeToProviderUpdates() {
        if LOCAL_TEST {
            return
        }
        
        guard !subscribedToProviderUpdates else { return }
        
        guard let user = PFUser.current(), let userId = user.objectId else { return }
        guard let query: PFQuery<User> = PFUser.query() as? PFQuery<User> else { return }
        
        
        query.whereKey("type", containedIn:[UserType.Plumber.rawValue.lowercased(), UserType.Electrician.rawValue.lowercased(), UserType.Handyman.rawValue.lowercased()])
        
        self.subscription = liveQueryClient.subscribe(query)
            .handle(Event.updated, { (_, object) in
                /*
                    if let providers = self.providers {
                        var changed = false
                        for user in providers {
                            if user.objectId == object.objectId, let index = providers.index(of: user) {
                                self.providers!.remove(at: index)
                                self.providers!.insert(object, at: index)
                                changed = true
                            }
                        }
                        if changed {
                            DispatchQueue.main.async(execute: {
                                print("received update for provider: \(object.objectId!)")
                                self.notify(.ProvidersUpdated, object: nil, userInfo: ["provider": object])
                            })
                        }
                    }
                */
                
                // some sort of crash. this solution sucks.
                self.queryProvidersAtPage(completionHandler: { (users) in
                    self.providers = users as? [User]
                    DispatchQueue.main.async(execute: {
                        print("received update for provider: \(object.objectId!)")
                        self.notify(.ProvidersUpdated, object: nil, userInfo: ["provider": object])
                    })
                }, errorHandler: { (error) in
                    print("could not load")
                })
            })
        self.subscribedToProviderUpdates = true
    }
        
    // MARK: Test function to generate providers and reviews in Parse. To run this again, existing users must be deleted
    func generateProviders() {
        /*
        var reviews = [
            Review(rating: 4.5, text: "Prompt, friendly, respectful, competent, knowledgable, experienced, prepared, professional service. Listened to my concerns and provided reassurance, answered questions. Scheduled conveniently. Two plumbers worked well together to accomplish all of the work in one day. Neat and clean, left the work area the same way that it was found."),
            Review(rating: 4.0, text: "It was an excellent experience from start to finish. I called Duke's in the morning, and Duke answered the phone. He came early that evening to assess the job. It was agreed that he would send two plumbers the next morning, including his 'drain man', at 8:30. The two men arrived and worked for 4 + hours getting all the jobs completed. They were congenial and professional, and fixed and explained everything to my satisfaction. It is a great relief to have these jobs completed."),
            Review(rating: 3.3, text: "Provided service earlier than expected. Arrived and did an excellent job. Crew was funny and polite. Even capped a leaky side sprayer on kitchen sink for no charge."),
            Review(rating: 4.5, text: "Called Generation 3 Electric due to an emergency situation. This is my first time using this company. Spoke with Cindy who was very sympathetic and helpful - she had someone at my place in less than an hour and a half to review the situation."),
            Review(rating: 3.3, text: "Would absolutely hire again - they were on time, professional, and fast."),
            Review(rating: 4.5, text: "I was extremely pleased with the work that was done by Mariano and his partner Lee. They basically worked miracles in reconstructing one of my walls as well as a staircase railing in order to hang a newly purchased interior door. There was no door in this location before. It separates the master bedroom from my 2nd floor hallway. The workmanship was extremely skilled and professional."),
            Review(rating: 1, text: "I called these people and left a message that I needed their help with a rather urgent project. I received no call back and waited foolishly for 3 days to post this review. Do not count on these people for anything as they don't even give the courtesy of a call back."),
            Review(rating: 1.0, text: "Horrible, had to request my money back due to only one worker showing up and the other working driving away. The worker that did show up did not speak any English."),
            Review(rating: 4, text: "They arrived on time, brought in tarps and plastic sheets to enclose the area they would be working.began work right away. They completed all the work they said they would in the time frame I purchased and left the house clean. the work is well done. I am very pleased.")
        ]
        let plumbers =
            [User(
                firstName: "William",
                lastName: "Henderson",
                type: .Plumber,
                rating: 5.0,
                ratePerMin: 4.3,
                skills: ["Raiding", "Leadership"],
                info: "ince 1977, Wm. Henderson Plumbing & Heating Inc has been providing quality plumbing, heating and cooling service throughout Delaware County and the Main Line. With a fleet of fully-stocked vehicles dispatched from our Broomall headquarters, we strive to provide our customers with prompt, professional service in the plumbing, heating and cooling fields. ",
                available: true),
             User(
                firstName: "Phil",
                lastName: "Parkinson",
                type: .Plumber,
                rating: 5.0,
                ratePerMin: 4.3,
                skills: ["Raiding", "Leadership"],
                info: "Phil Parkinson Plumbing is owner operated and takes an enormous amount of pride in being the very best plumber in the area. What you can expect when you hire Phil is exceptional service, with an honest and professional approach and a goal to make the customer happy with their experience.",
                available: true),
             User(
                firstName: "William",
                lastName: "Wing",
                type: .Plumber,
                rating: 5.0,
                ratePerMin: 4.3,
                skills: ["Raiding", "Leadership"],
                info: "Duke's Plumbing, a family owned & operated business with over 25 years experience in the plumbing and heating field. We take pride in what we do and treat our clients like family.",
                available: false)
                ]
        let electricians =
            [User(
                firstName: "Joseph",
                lastName: "Voci",
                type: .Electrician,
                rating: 5.0,
                ratePerMin: 4.3,
                skills: ["Raiding", "Leadership"],
                info: "Residential family owned electrical Business Established in 2005, our company's mission is to provide timely professional services with honest prices. ",
                available: true),
             User(
                firstName: "Bill",
                lastName: "Lutz",
                type: .Electrician,
                rating: 5.0,
                ratePerMin: 4.3,
                skills: ["Raiding", "Leadership"],
                info: "Voted Philadelphia Magazine's Best of Philly 2012, Best Electrician. No sub contracting. May contact through email. Gen3 is always available to go over any other estimates you may have from competing electricians. We may not be able to beat every price but we are always happy to help you understand and make an educated decision. ",
                available: true),
             User(
                firstName: "Gerti",
                lastName: "Tefa",
                type: .Electrician,
                rating: 5.0,
                ratePerMin: 4.3,
                skills: ["Raiding", "Leadership"],
                info: "Green Electric Heating & Cooling Inc is a licensed and insured BBB accredited business. Green Heating Cooling & Electric offers your family or business the best HVAC products and services. We serve our customers with a commitment to service and value. ",
                available: false)
        ]
        let handymen =
            [User(
                firstName: "Mariano",
                lastName: "Di Giacomo",
                type: .Handyman,
                rating: 5.0,
                ratePerMin: 4.3,
                skills: ["Raiding", "Leadership"],
                info: "If you're looking for a reliable and dedicated company to help with repairs and enhancements to your home, then we have an answer Simple Solutions! ",
                available: true),
             User(
                firstName: "Steve",
                lastName: "Gengaro",
                type: .Handyman,
                rating: 5.0,
                ratePerMin: 4.3,
                skills: ["Raiding", "Leadership"],
                info: "Steve's Remodeling & Handyman, LLC is a small, local business. Steve sees                 your project through himself from estimate to finish without subs. ",
                available: true),
             User(
                firstName: "John",
                lastName: "Amadi",
                type: .Handyman,
                rating: 5.0,
                ratePerMin: 4.3,
                skills: ["Raiding", "Leadership"],
                info: "We can take care of anything for you from landscaping to roofing. Our main goal is customer satisfaction and we always make sure everything is done right!",
                available: false)
        ]
        for user in plumbers {
            user.username = "\(user.firstName!).\(user.lastName!)"
            user.password = "test"
            user.signUpInBackgroundWithBlock({ (success, error) in
                print("done")
                let review = reviews[0]
                review.provider = user
                reviews.removeFirst()
                review.saveInBackground()
            })
        }
        for user in electricians {
            user.username = "\(user.firstName!).\(user.lastName!)"
            user.password = "test"
            user.signUpInBackgroundWithBlock({ (success, error) in
                print("done")
                let review = reviews[0]
                review.provider = user
                reviews.removeFirst()
                review.saveInBackground()
            })
        }
        for user in handymen {
            user.username = "\(user.firstName!).\(user.lastName!)"
            user.password = "test"
            user.signUpInBackgroundWithBlock({ (success, error) in
                print("done")
                let review = reviews[0]
                review.provider = user
                reviews.removeFirst()
                review.saveInBackground()
            })
        }
         */
    }
}
