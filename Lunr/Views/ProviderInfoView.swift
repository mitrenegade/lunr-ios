import UIKit
import Parse

class ProviderInfoView: NibLoadableView {

    @IBOutlet weak var availableImageView: UIImageView!
    @IBOutlet weak var availableLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceRateLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var tagsView: ResizableTagView!
    @IBOutlet weak var constraintTagsViewHeight: NSLayoutConstraint!
    
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
        
        self.tagsView.delegate = self
        
    }
    
    func configureForProvider(_ provider: User) {
        self.provider = provider
        self.nameLabel.text = provider.displayString
        let ratingString = provider.rating == 0 ? "-.-" : String(format: "%.1f", provider.rating)
        self.ratingLabel.text = ratingString
        self.priceRateLabel.text = "$\(provider.ratePerMin)/min"
        self.configureAvailability(provider.available)

        self.configureFavoriteIcon()
        self.tagsView.configureWithTags(tagStrings: provider.skills)
    }

    func configureAvailability(_ isAvailable: Bool) {
        if isAvailable {
            self.availableLabel.text = "Currently Available"
            self.availableImageView.image = UIImage(imageLiteralResourceName: "available")
            self.nameLabel.alpha = 1
        } else {
            self.availableLabel.text = "Unavailable"
            self.availableImageView.image = UIImage(imageLiteralResourceName: "unavailable")
            self.nameLabel.alpha = 0.5
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

}

extension ProviderInfoView: ResizableTagViewDelegate {
    func didUpdateHeight(height: CGFloat) {
        print("new skills height: \(height)")
        self.constraintTagsViewHeight.constant = height
    }
}
