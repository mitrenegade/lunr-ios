import UIKit

class ProviderSkillTagCollectionViewCell: UICollectionViewCell, LoadableInit {

    @IBOutlet weak var userContentView: UIView!
    @IBOutlet weak var skillLabel: UILabel!

    var nibName: String {
        get {
            return "ProviderSkillTagCollectionViewCell"
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    func commonInit() {
        Bundle.main.loadNibNamed(self.nibName, owner: self, options: nil)

        self.userContentView.frame = self.bounds
        self.userContentView.autoresizingMask = [.flexibleWidth]
        self.userContentView.layer.cornerRadius = 5

        self.contentView.addSubview(userContentView)
    }

    func configureForSkill(_ skill: String) {
        self.skillLabel.text = skill
    }
}
