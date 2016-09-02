import UIKit

class ProviderTableViewCell: UITableViewCell {

    @IBOutlet weak var providerInfoView: ProviderInfoView!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.selectionStyle = .None
        self.backgroundColor = UIColor.clearColor()
        self.clipsToBounds = false

        self.contentView.addShadow()
        self.contentView.backgroundColor = UIColor.clearColor()
        self.contentView.clipsToBounds = false
    }

    func configureForProvider(provider: User) {
        self.providerInfoView.configureForProvider(provider)
    }
}
