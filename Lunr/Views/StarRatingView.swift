import UIKit

protocol StarRatingViewDelegate {
    func starRatingSelected(rating: Int);
}

class StarRatingView: NibLoadableView {

    @IBOutlet var starRatingButtons: [UIButton]!

    var delegate : StarRatingViewDelegate?
    var currentRating: Int = 0 {
        didSet {
            if currentRating > 0 && currentRating <= 5 {
                self.configureRatingImagesForRating(currentRating)
            }
            else {
                currentRating = oldValue
                self.configureRatingImagesForRating(currentRating)
            }
        }
    }

    override var nibName: String {
        get {
            return "StarRatingView"
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.configureRatingImagesForRating(0)
    }

    @IBAction func starRatingButtonPressed(sender: UIButton) {
        self.currentRating = sender.tag
        self.delegate?.starRatingSelected(sender.tag)
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
