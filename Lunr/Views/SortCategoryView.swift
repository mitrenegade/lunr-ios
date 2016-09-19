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
        let category = SortCategory(rawValue: sender.tag)!
        self.highlightButtonForCategory(category)
        self.delegate!.sortCategoryWasSelected(category)
    }
    
    // MARK: selectors
    func toggleButton(button: UIButton, selected: Bool) {
        let category = SortCategory(rawValue: button.tag)!
        let image: UIImage
        switch category {
        case .Rating:
            image = UIImage(named: "star")!.imageWithRenderingMode(.AlwaysTemplate)
        case .Price:
            image = UIImage(named: "dollarsign")!.imageWithRenderingMode(.AlwaysTemplate)
        case .Favorites:
            image = UIImage(named: "heart")!.imageWithRenderingMode(.AlwaysTemplate)
        default:
            image = UIImage(named: "atoz")!.imageWithRenderingMode(.AlwaysTemplate)
        }
        
        button.setImage(image, forState: .Normal)
        button.tintColor = selected ? UIColor.lunr_darkBlue() : UIColor.lunr_grayText()
    }
    
    func highlightButtonForCategory(category: SortCategory) {
        for button in [sortAlphabeticallyButton, sortByFavoritesButton, sortByPriceButton, sortByRatingButton] {
            self.toggleButton(button, selected: button.tag == category.rawValue)
        }
    }
}