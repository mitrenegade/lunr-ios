import UIKit

protocol SortCategoryProtocol {
    func sortCategoryWasSelected(_ sortCategory : SortCategory)
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

    @IBAction func sortButtonWasPressed(_ sender: UIButton) {
        let category = SortCategory(rawValue: sender.tag)!
        self.highlightButtonForCategory(category)
        self.delegate!.sortCategoryWasSelected(category)
    }
    
    // MARK: selectors
    func toggleButton(_ button: UIButton, selected: Bool) {
        let category = SortCategory(rawValue: button.tag)!
        let image: UIImage
        switch category {
        case .rating:
            image = UIImage(named: "star")!.withRenderingMode(.alwaysTemplate)
        case .price:
            image = UIImage(named: "dollarsign")!.withRenderingMode(.alwaysTemplate)
        case .favorites:
            image = UIImage(named: "heart")!.withRenderingMode(.alwaysTemplate)
        default:
            image = UIImage(named: "atoz")!.withRenderingMode(.alwaysTemplate)
        }
        
        button.setImage(image, for: UIControlState())
        button.tintColor = selected ? UIColor.lunr_darkBlue() : UIColor.lunr_grayText()
    }
    
    func highlightButtonForCategory(_ category: SortCategory) {
        for button in [sortAlphabeticallyButton, sortByFavoritesButton, sortByPriceButton, sortByRatingButton] {
            self.toggleButton(button!, selected: button?.tag == category.rawValue)
        }
    }
}
