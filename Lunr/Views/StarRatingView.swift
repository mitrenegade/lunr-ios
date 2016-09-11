import UIKit

protocol StarRatingViewDelegate {
    func starRatingSelected(rating: Int);
}

class StarRatingView: NibLoadableView {

    @IBOutlet weak var oneStarButton: UIButton!
    @IBOutlet weak var twoStarButton: UIButton!
    @IBOutlet weak var threeStarButton: UIButton!
    @IBOutlet weak var fourStarButton: UIButton!
    @IBOutlet weak var fiveStarButton: UIButton!
    var delegate : StarRatingViewDelegate?

    override var nibName: String {
        get {
            return "StarRatingView"
        }
    }

    @IBAction func starRatingButtonPressed(sender: UIButton) {
        self.delegate!.starRatingSelected(sender.tag)
        self.configureRatingImagesForRating(sender.tag)
    }

    func configureRatingImagesForRating(rating: Int) {
        for button : UIButton in [self.oneStarButton, self.twoStarButton, self.threeStarButton,
                                  self.fourStarButton, self.fiveStarButton] {
            if button.tag <= rating {
                button.setImage(UIImage(imageLiteral: "star"), forState: .Normal)
            }
            else {
                button.setImage(UIImage(imageLiteral: "heart"), forState: .Normal)
                //TODO: replace with actual asset
            }
        }
    }
}
