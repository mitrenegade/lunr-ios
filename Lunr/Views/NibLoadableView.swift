import UIKit

protocol LoadableInit {
    // an attempt at making this code reusable between UIView and UICollectionViewCell
    var nibName: String { get }
    func commonInit()
}

class NibLoadableView: UIView, LoadableInit {
    @IBOutlet weak var contentView: UIView!

    override init(frame: CGRect) { // for using CustomView in code
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) { // for using CustomView in IB
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(self.nibName, owner: self, options: nil)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(contentView)
    }
    
    var nibName: String {
        get {
            preconditionFailure("Subclass of NibLoadableView must override by returning name of the nib")
        }
    }
}
