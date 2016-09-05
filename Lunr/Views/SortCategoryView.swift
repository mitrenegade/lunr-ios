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

        self.addShadow()
    }

    override var nibName: String {
        get {
            return "SortCategoryView"
        }
    }

    // MARK: Event Methods

    @IBAction func sortButtonWasPressed(sender: UIButton) {
        self.delegate!.sortCategoryWasSelected(SortCategory(rawValue: sender.tag)!)
    }
}