import UIKit

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
        let sortCategory: SortCategory
        switch sender.tag {
        case SortCategory.Alphabetical.rawValue:
            sortCategory = .Alphabetical
        case SortCategory.Favorites.rawValue:
            sortCategory = .Favorites
        case SortCategory.Price.rawValue:
            sortCategory = .Price
        case SortCategory.Rating.rawValue:
            sortCategory = .Rating
        default:
            sortCategory = .Alphabetical
        }
        self.delegate!.sortCategoryWasSelected(sortCategory)
    }
}