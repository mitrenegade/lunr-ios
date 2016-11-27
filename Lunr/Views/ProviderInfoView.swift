import UIKit
import Parse

class ProviderInfoView: NibLoadableView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var availableImageView: UIImageView!
    @IBOutlet weak var availableLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceRateLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var skillCollectionView: UICollectionView!
    var skills: [String]?
    var provider: User?

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

        self.skillCollectionView.backgroundColor = UIColor.clear
        self.skillCollectionView.register(ProviderSkillTagCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: "ProviderSkillTagCollectionViewCell")

        if let flowLayout = self.skillCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = CGSize(width: 50, height: 25)
        }
    }

    func configureForProvider(_ provider: User) {
        self.provider = provider
        self.nameLabel.text = provider.displayString
        self.ratingLabel.text = "\(provider.rating)"
        self.priceRateLabel.text = "$\(provider.ratePerMin)/min"
        self.configureAvailability(provider.available)
        self.skills = provider.skills
        
        self.configureFavoriteIcon()
        
        self.skillCollectionView.reloadData()
    }

    func configureAvailability(_ isAvailable: Bool) {
        if isAvailable {
            self.availableLabel.text = "Currently Available"
            self.availableImageView.image = UIImage(imageLiteralResourceName: "available")
        } else {
            self.availableLabel.text = "Unavailable"
            self.availableImageView.image = UIImage(imageLiteralResourceName: "unavailable")
        }
    }

    func configureFavoriteIcon() {
        guard let user = PFUser.current() as? User else { return }
        guard let provider = self.provider else { return }
        if provider.isFavoriteOf(user) {
            // TODO: use different image instead of template?
            self.favoriteButton.setImage(UIImage(named: "heart")!.withRenderingMode(.alwaysTemplate), for: UIControlState())
            self.favoriteButton.tintColor = UIColor.red
        }
        else {
            // TODO: use different image instead of template?
            self.favoriteButton.setImage(UIImage(named: "heart")!.withRenderingMode(.alwaysOriginal), for: UIControlState())
        }
    }
    
    // MARK: Event Methods

    @IBAction func favoriteButtonWasPressed(_ sender: UIButton) {
        
        // make request to favorite this provider
        guard let user = PFUser.current() as? User else { return }
        guard let provider = self.provider else { return }
        
        user.toggleFavorite(provider) { (success) in
            // update the image of the button to reflect if favorited
            self.configureFavoriteIcon()
        }
    }

    // MARK: UICollectionViewDataSource Methods

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProviderSkillTagCollectionViewCell", for: indexPath) as! ProviderSkillTagCollectionViewCell
        if let skills = self.skills {
            cell.configureForSkill(skills[indexPath.row])
        }
        return cell

    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let skills = self.skills {
            return skills.count
        }
        return 0
    }
}
