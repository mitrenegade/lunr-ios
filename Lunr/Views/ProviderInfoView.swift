import UIKit

class ProviderInfoView: NibLoadableView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var availableImageView: UIImageView!
    @IBOutlet weak var availableLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceRateLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var skillCollectionView: UICollectionView!
    var skills: [String]?

    override var nibName: String {
        get {
            return "ProviderInfoView"
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.layer.cornerRadius = 8
        self.clipsToBounds = true

        self.ratingLabel.layer.cornerRadius = 8
        self.ratingLabel.clipsToBounds = true

        self.skillCollectionView.backgroundColor = UIColor.clearColor()
        self.skillCollectionView.registerClass(ProviderSkillTagCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: "ProviderSkillTagCollectionViewCell")

        if let flowLayout = self.skillCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = CGSizeMake(50, 25)
        }
    }

    func configureForProvider(provider: Provider) {
        self.nameLabel.text = provider.name
        self.ratingLabel.text = "\(provider.rating)"
        self.priceRateLabel.text = "$\(provider.ratePerMin)/min"
        self.configureAvailability(provider.available)
        self.skills = provider.skills
    }

    func configureAvailability(isAvailable: Bool) {
        if isAvailable {
            self.availableLabel.text = "Currently Available"
            self.availableImageView.image = UIImage(imageLiteral: "available")
        } else {
            self.availableLabel.text = "Unavailable"
            self.availableImageView.image = UIImage(imageLiteral: "unavailable")
        }
    }

    // MARK: Event Methods

    @IBAction func favoriteButtonWasPressed(sender: UIButton) {
        // TODO: make request to favorite this provider
        // TODO: update the image of the button to reflect if favorited
    }

    // MARK: UICollectionViewDataSource Methods

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ProviderSkillTagCollectionViewCell", forIndexPath: indexPath) as! ProviderSkillTagCollectionViewCell
        guard let skills = self.skills else { return }
        cell.configureForSkill(skills[indexPath.row])
        return cell

    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let skills = self.skills {
            return skills.count
        }
        return 0
    }
}
