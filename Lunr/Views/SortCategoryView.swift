import UIKit

enum SortCategory : Int {
    case Alphabetical = 0
    case Rating = 1
    case Price = 2
    case Favorites = 3
}

protocol SortCategoryProtocol {
    func sortCategoryWasSelected(sortCategory : SortCategory)
}

class SortCategoryView: NibLoadableView {

    @IBOutlet weak var sortAlphabeticallyButton: UIButton!
    @IBOutlet weak var sortByRatingButton: UIButton!
    @IBOutlet weak var sortByPriceButton: UIButton!
    @IBOutlet weak var sortByFavoritesButton: UIButton!
    var delegate : SortCategoryProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.sortAlphabeticallyButton.tag = 0
        self.sortByRatingButton.tag = 1
        self.sortByPriceButton.tag = 2
        self.sortByFavoritesButton.tag = 3

        self.addShadow()
    }

    override var nibName: String {
        get {
            return "SortCategoryView"
        }
    }

    // MARK: Event Methods

    @IBAction func sortButtonWasPressed(sender: UIButton) {
        //self.delegate!.sortCategoryWasSelected(sender.tag as! SortCategory)
        //TODO: Not sure how to convert this Int into another Int that is a SortCategory enum.
    }
}