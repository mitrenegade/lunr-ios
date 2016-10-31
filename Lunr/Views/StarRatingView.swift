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
        var image : UIImage?

        for button : UIButton in self.starRatingButtons {
            if button.tag <= rating {
                image = UIImage(named: "star")!
            } else {
                image = UIImage(named: "gray_star")!
            }

            button.setImage(image, forState: .Normal)
        }
    }
}
