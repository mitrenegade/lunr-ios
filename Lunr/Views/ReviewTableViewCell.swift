import UIKit

class ReviewTableViewCell: UITableViewCell {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var ratingLabel: UILabel!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.backgroundColor = UIColor.lunr_iceBlue()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    func configureForReview(review: Review) {
        self.textView.text = review.text
        self.textView.font = UIFont.futuraMediumWithSize(14)

        self.ratingLabel.text = "\(review.rating)"
        self.ratingLabel.layer.cornerRadius = 8
        self.ratingLabel.clipsToBounds = true
    }
}