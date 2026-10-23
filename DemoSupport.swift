import UIKit

final class TenantCardSubmission {
    var submissionType: String?
    var ownerID: String?
    var propertyID: String?
    var unitID: String?
    var renterID: String?
    var address: String?
    var city: String?
    var state: String?
    var zip: String?

    var verb: String {
        switch submissionType {
        case "prequalification": return "prequalify"
        default: return "apply"
        }
    }

    var fullAddress: String {
        "\(address ?? ""), \(unitID ?? ""), \(city ?? ""), \(state ?? "") \(zip ?? "")"
    }

    init(address: String, unitID: String, city: String, state: String, zip: String) {
        self.address = address
        self.unitID = unitID
        self.city = city
        self.state = state
        self.zip = zip
        submissionType = nil
    }
}

enum TenantToDoAlertType {
    case applicationInvite
}

class RentRediPlusHomeVC: UIViewController {
    var applicationPopup = UIView()
    var tenantCardSubmission: TenantCardSubmission?
    var hasExistingInviteApplication = false
    let ref = MockDatabaseReference()

    func hideTenantToDoAlert() {}
    func setupTenantToDoAlert() {}

    func applyPrequalifyVerb(noun: String) -> String {
        noun == "prequalification" ? "Prequalify" : "Apply"
    }

    func updateToDoAlert(
        title: String,
        description: String,
        type: TenantToDoAlertType
    ) {}
}

final class MockDatabaseReference {
    @discardableResult
    func child(_ path: String) -> MockDatabaseReference { self }
    func setValue(_ value: Any?) {}
}

final class ApplyHomeVC: UIViewController {
    var tenantCardSubmission: TenantCardSubmission?
    weak var homeVC: RentRediPlusHomeVC?
}

final class PrequalifyHomeVC: UIViewController {
    var tenantCardSubmission: TenantCardSubmission?
}

final class DatabaseFunctions {
    func log(message: Any) {
        print(message)
    }
}

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

final class ApplicationApartmentPhotoCell: UICollectionViewCell {
    let apartmentPhoto = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureImageView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureImageView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        apartmentPhoto.image = nil
    }

    private func configureImageView() {
        apartmentPhoto.translatesAutoresizingMaskIntoConstraints = false
        apartmentPhoto.contentMode = .scaleAspectFill
        apartmentPhoto.clipsToBounds = true
        contentView.addSubview(apartmentPhoto)
        NSLayoutConstraint.activate([
            apartmentPhoto.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            apartmentPhoto.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            apartmentPhoto.topAnchor.constraint(equalTo: contentView.topAnchor),
            apartmentPhoto.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

extension String {
    func capitalizeFirstLetter() -> String {
        prefix(1).uppercased() + dropFirst()
    }
}

enum DemoImageFactory {
    private struct ImageDescription {
        let title: String
        let subtitle: String
        let color: UIColor
        let symbol: String
    }

    static func makeImageURLs() -> [URL] {
        let descriptions = [
            ImageDescription(title: "Living Room", subtitle: "Bright and spacious", color: UIColor(red: 0.23, green: 0.55, blue: 0.78, alpha: 1), symbol: "sofa.fill"),
            ImageDescription(title: "Kitchen", subtitle: "Modern finishes", color: UIColor(red: 0.24, green: 0.66, blue: 0.51, alpha: 1), symbol: "fork.knife"),
            ImageDescription(title: "Bedroom", subtitle: "Quiet and comfortable", color: UIColor(red: 0.53, green: 0.39, blue: 0.72, alpha: 1), symbol: "bed.double.fill")
        ]

        return descriptions.enumerated().compactMap { index, description in
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 900, height: 650))
            let image = renderer.image { context in
                description.color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 900, height: 650))

                let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 132, weight: .light)
                let symbol = UIImage(systemName: description.symbol, withConfiguration: symbolConfiguration)?
                    .withTintColor(.white.withAlphaComponent(0.9), renderingMode: .alwaysOriginal)
                symbol?.draw(in: CGRect(x: 350, y: 125, width: 200, height: 170))

                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 52, weight: .bold),
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: paragraph
                ]
                let subtitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 28, weight: .regular),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.85),
                    .paragraphStyle: paragraph
                ]

                description.title.draw(in: CGRect(x: 50, y: 350, width: 800, height: 70), withAttributes: titleAttributes)
                description.subtitle.draw(in: CGRect(x: 50, y: 430, width: 800, height: 50), withAttributes: subtitleAttributes)
            }

            guard let data = image.pngData() else { return nil }
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("apartment-demo-\(index).png")
            do {
                try data.write(to: url, options: .atomic)
                return url
            } catch {
                assertionFailure("Unable to write mock image: \(error)")
                return nil
            }
        }
    }
}
