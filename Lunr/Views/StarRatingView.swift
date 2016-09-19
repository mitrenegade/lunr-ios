import UIKit

protocol StarRatingViewDelegate {
    func starRatingSelected(rating: Int);
}

class StarRatingView: NibLoadableView {

    @IBOutlet var starRatingButtons: [UIButton]!

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
        for button : UIButton in self.starRatingButtons {
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
