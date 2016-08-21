//
//  ProviderDetailViewController.swift
//  Lunr
//
//  Created by Randall Spence on 8/6/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

private let callButtonHeight = 50

class ProviderDetailViewController : UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var callButtonView: UIView!
    @IBOutlet weak var callButton: UIButton!

    let provider : Provider

    init(provider: Provider) {
        self.provider = provider
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        let testReview = Review(text: "John Snow is awesome! He truly is the King of the North!", rating: 5.0)
        let testProvider = Provider(name: "John Snow", rating: 5.0, reviews: [testReview], ratePerMin: 4.3, skills: ["Raiding", "Leadership"], info: "John Snow is the son of Rhaegar and Lyanna. Oops that was a spoiler! Well, that's your fault cause you should be caught up on the show...")
        self.provider = testProvider
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.provider.name
        //self.navigationController?.navigationBar.translucent = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back-arrow")!, style:.Plain, target:self, action:nil)
        self.tableView.registerNib(UINib(nibName: "DetailTableViewCell", bundle: nil), forCellReuseIdentifier: "DetailTableViewCell")
        self.tableView.registerNib(UINib(nibName: "ReviewTableViewCell", bundle: nil), forCellReuseIdentifier: "ReviewTableViewCell")
        self.tableView.separatorStyle = .SingleLine
        setupCallButton()
    }

    func setupCallButton() {
        // TODO: Localize
        // TODO: Change to attributed title when the font is added
        self.callButton.setTitle("Call Now", forState: .Normal)
        self.callButton.setTitleColor(.whiteColor(), forState: .Normal)
        // TODO: Move to theme file or UIAppearance Proxy
        self.callButton.backgroundColor = UIColor(red: 46/255, green: 56/255, blue: 91/255, alpha: 1.0)
    }

    @IBAction func callButtonTapped(sender: AnyObject) {
        print("Let's call \(provider.name)")
    }


}

extension ProviderDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        return provider.reviews.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell: DetailTableViewCell = tableView.dequeueReusableCellWithIdentifier("DetailTableViewCell", forIndexPath: indexPath) as! DetailTableViewCell
            cell.textView.text = provider.info

            return cell
        }
        let cell: ReviewTableViewCell = tableView.dequeueReusableCellWithIdentifier("ReviewTableViewCell", forIndexPath: indexPath) as! ReviewTableViewCell
        cell.textView.text = provider.reviews[indexPath.row].text
        return cell
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // TODO: Make cells self sizing
        return 200
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 { return "Reviews:" }
        return nil
    }
}
