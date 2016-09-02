import UIKit

class DetailTableViewCell: UITableViewCell {

    @IBOutlet weak var providerInfoView: ProviderInfoView!
    @IBOutlet weak var textView: UITextView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.backgroundColor = UIColor.lunr_iceBlue()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    func configureForProvider(provider: User) {
        self.providerInfoView.configureForProvider(provider)
        self.textView.text = provider.info
        self.textView.font = UIFont.futuraMediumWithSize(14)
    }
}