import UIKit

class ProviderTableViewCell: UITableViewCell {

    @IBOutlet weak var providerInfoView: ProviderInfoView!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = false

        self.contentView.addShadow()
        self.contentView.backgroundColor = UIColor.clear
        self.contentView.clipsToBounds = false
    }

    func configureForProvider(_ provider: User) {
        self.providerInfoView.configureForProvider(provider)
    }
}
