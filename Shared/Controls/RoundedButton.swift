import UIKit

@IBDesignable
final class roundedButton: UIButton {
    @IBInspectable var rounded = false {
        didSet { updateAppearance() }
    }

    @IBInspectable var border = false {
        didSet { updateAppearance() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateAppearance()
    }

    private func updateAppearance() {
        layer.cornerRadius = rounded ? bounds.height / 2 : 0
        layer.borderWidth = border ? 1 : 0
        layer.borderColor = tintColor.cgColor
        clipsToBounds = rounded
    }
}
