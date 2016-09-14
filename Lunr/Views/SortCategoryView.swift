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
        self.delegate!.sortCategoryWasSelected(SortCategory(rawValue: sender.tag)!)
        
        for button in [sortAlphabeticallyButton, sortByFavoritesButton, sortByPriceButton, sortByRatingButton] {
            let category = SortCategory(rawValue: button.tag)!
            self.toggleButtonForCategory(category, selected: button == sender)
        }
    }
    
    // MARK: selectors
    func toggleButtonForCategory(category: SortCategory, selected: Bool) {
        let button: UIButton
        let image: UIImage
        switch category {
        case .Rating:
            button = self.sortByRatingButton
            image = UIImage(named: "star")!.imageWithRenderingMode(.AlwaysTemplate)
        case .Price:
            button = self.sortByPriceButton
            image = UIImage(named: "dollarsign")!.imageWithRenderingMode(.AlwaysTemplate)
        case .Favorites:
            button = self.sortByFavoritesButton
            image = UIImage(named: "heart")!.imageWithRenderingMode(.AlwaysTemplate)
        default:
            button = self.sortAlphabeticallyButton
            image = UIImage(named: "atoz")!.imageWithRenderingMode(.AlwaysTemplate)
        }
        
        button.setImage(image, forState: .Normal)
        button.tintColor = selected ? UIColor.lunr_darkBlue() : UIColor.lunr_grayText()
    }
}